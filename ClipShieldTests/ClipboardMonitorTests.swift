import Testing
import Foundation
@testable import ClipShield

final class MockClipboardProvider: ClipboardProvider {
    var _changeCount = 0
    var _content: String?

    var changeCount: Int { _changeCount }

    func string() -> String? { _content }

    func setString(_ string: String) {
        _content = string
        _changeCount += 1
    }

    func clear() {
        _content = nil
        _changeCount += 1
    }

    func simulateCopy(_ text: String) {
        _content = text
        _changeCount += 1
    }
}

private func makeMonitor(provider: MockClipboardProvider) -> ClipboardMonitor {
    let settings = SettingsStore(userDefaults: UserDefaults(suiteName: "test-\(UUID())")!)
    return ClipboardMonitor(
        settings: settings,
        provider: provider,
        pollInterval: 0.05,
        debounceInterval: 0.01
    )
}

@Suite("ClipboardMonitor")
struct ClipboardMonitorTests {
    @Test("detects sensitive data on clipboard change")
    func detectsSensitiveData() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        monitor.start()
        provider.simulateCopy("4111111111111111")
        monitor.checkClipboard()

        #expect(monitor.isCountingDown)
        monitor.stop()
    }

    @Test("ignores clean clipboard content")
    func ignoresCleanContent() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        monitor.start()
        provider.simulateCopy("Hello world")
        monitor.checkClipboard()

        #expect(monitor.status == .idle)
        monitor.stop()
    }

    @Test("cancels countdown when clipboard changes to clean content")
    func cancelsCountdown() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        monitor.start()

        provider.simulateCopy("4111111111111111")
        monitor.checkClipboard()
        #expect(monitor.isCountingDown)

        Thread.sleep(forTimeInterval: 0.02)
        provider.simulateCopy("Hello world")
        monitor.checkClipboard()
        #expect(monitor.status == .idle)

        monitor.stop()
    }

    @Test("clearNow clears clipboard immediately")
    func clearNow() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        provider.simulateCopy("4111111111111111")
        monitor.clearNow()

        #expect(provider._content == nil)
        #expect(monitor.detectionCount == 1)
        #expect(monitor.status == .cleared)
    }

    @Test("handlePasteDetected shortens countdown to postPasteDelay")
    func pasteShortensCountdown() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        monitor.start()
        provider.simulateCopy("4111111111111111")
        monitor.checkClipboard()
        #expect(monitor.isCountingDown)

        monitor.handlePasteDetected()
        if case .postPaste(let seconds) = monitor.status {
            #expect(seconds == monitor.settings.postPasteDelay)
        } else {
            Issue.record("Expected .postPaste status, got \(monitor.status)")
        }
        monitor.stop()
    }

    @Test("handlePasteDetected is no-op when idle")
    func pasteNoOpWhenIdle() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        monitor.handlePasteDetected()
        #expect(monitor.status == .idle)
    }

    @Test("handlePasteDetected is no-op when cleared")
    func pasteNoOpWhenCleared() {
        let provider = MockClipboardProvider()
        let monitor = makeMonitor(provider: provider)

        provider.simulateCopy("4111111111111111")
        monitor.clearNow()
        #expect(monitor.status == .cleared)

        monitor.handlePasteDetected()
        #expect(monitor.status == .cleared)
    }
}
