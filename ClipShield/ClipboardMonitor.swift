import AppKit
import Foundation
import Combine
import UserNotifications
import os

private let logger = Logger(subsystem: "com.maferland.clipshield", category: "Monitor")

enum MonitorStatus: Equatable {
    case idle
    case countdown(secondsLeft: Int)
    case postPaste(secondsLeft: Int)
    case cleared
}

final class ClipboardMonitor: ObservableObject {
    let settings: SettingsStore
    private let provider: ClipboardProvider
    private let pollInterval: TimeInterval
    private let debounceInterval: TimeInterval

    @Published var status: MonitorStatus = .idle
    @Published var detectionCount: Int = 0
    @Published var lastDetectionLabel: String?

    var isCountingDown: Bool {
        switch status {
        case .countdown, .postPaste: return true
        default: return false
        }
    }

    private var timer: Timer?
    private var clearTimer: Timer?
    private var countdownTimer: Timer?
    private var eventMonitor: Any?
    private var lastChangeCount: Int = 0
    private var lastSanitizedAt: Date?
    private var detectedText: String?
    private var cancellables = Set<AnyCancellable>()

    init(
        settings: SettingsStore = SettingsStore(),
        provider: ClipboardProvider = SystemClipboardProvider(),
        pollInterval: TimeInterval = 0.5,
        debounceInterval: TimeInterval = 0.3
    ) {
        self.settings = settings
        self.provider = provider
        self.pollInterval = pollInterval
        self.debounceInterval = debounceInterval

        settings.$isEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                if enabled { self?.start() } else { self?.stop() }
            }
            .store(in: &cancellables)
    }

    func start() {
        stop()
        lastChangeCount = provider.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        installPasteMonitor()
        logger.info("Monitor started (poll: \(self.pollInterval)s, delay: \(self.settings.clearDelay)s)")
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
        cancelCountdown()
    }

    func clearNow() {
        cancelCountdown()
        provider.clear()
        lastChangeCount = provider.changeCount
        detectedText = nil
        lastSanitizedAt = Date()
        detectionCount += 1
        status = .cleared
        sendNotification("Sensitive data cleared from clipboard")
        logger.info("Clipboard cleared manually")
    }

    func checkClipboard() {
        guard settings.isEnabled else { return }

        let currentCount = provider.changeCount
        guard currentCount != lastChangeCount else { return }

        if let lastSanitizedAt, Date().timeIntervalSince(lastSanitizedAt) < debounceInterval {
            return
        }

        lastChangeCount = currentCount
        guard let text = provider.string() else { return }

        let detections = detect(text, enabled: settings.enabledPatterns)

        if !detections.isEmpty && detectedText != text {
            // New sensitive data — mark concealed and start countdown
            provider.setString(text) // re-writes with ConcealedType
            lastChangeCount = provider.changeCount
            lastSanitizedAt = Date()
            detectedText = text
            lastDetectionLabel = detections[0].label
            startCountdown()
            logger.info("Detected: \(detections[0].label)")
        } else if detections.isEmpty && detectedText != nil {
            // Clipboard changed to non-sensitive content — cancel
            cancelCountdown()
            detectedText = nil
            status = .idle
        }
    }

    private func startCountdown(delay: Int? = nil, postPaste: Bool = false) {
        cancelCountdown()

        let seconds = delay ?? settings.clearDelay
        var remaining = seconds

        let statusUpdate: (Int) -> MonitorStatus = postPaste
            ? { .postPaste(secondsLeft: $0) }
            : { .countdown(secondsLeft: $0) }

        status = statusUpdate(remaining)

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            remaining -= 1
            if remaining <= 0 {
                timer.invalidate()
                self?.expireClear()
            } else {
                self?.status = statusUpdate(remaining)
            }
        }

        clearTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.expireClear()
        }
    }

    func handlePasteDetected() {
        guard isCountingDown else { return }
        logger.info("Paste detected — shortening countdown to \(self.settings.postPasteDelay)s")
        startCountdown(delay: settings.postPasteDelay, postPaste: true)
    }

    private func installPasteMonitor() {
        guard AXIsProcessTrusted() else {
            logger.info("Accessibility not granted — paste detection disabled")
            return
        }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // keyCode 9 = V, check for Cmd modifier
            if event.keyCode == 9, event.modifierFlags.contains(.command) {
                self?.handlePasteDetected()
            }
        }
    }

    private func expireClear() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        clearTimer?.invalidate()
        clearTimer = nil

        provider.clear()
        lastChangeCount = provider.changeCount
        detectedText = nil
        lastSanitizedAt = Date()
        detectionCount += 1
        status = .cleared
        sendNotification("Sensitive data cleared from clipboard")
        logger.info("Clipboard auto-cleared after delay")
    }

    private func cancelCountdown() {
        clearTimer?.invalidate()
        clearTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func sendNotification(_ message: String) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = "ClipShield"
        content.body = message
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
