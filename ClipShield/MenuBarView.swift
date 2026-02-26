import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var settings: SettingsStore
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            statusBanner
            primaryToggles
            Divider()
            detectionToggles
            Divider()
            timingSection
            Divider()
            actions
        }
        .frame(width: 240)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text("ClipShield")
                        .font(.headline)
                    Text(appVersion)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if monitor.detectionCount > 0 {
                    Text("\(monitor.detectionCount) cleared")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            statusDot
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Status banner

    @ViewBuilder
    private var statusBanner: some View {
        if let banner = activeBanner {
            HStack {
                Image(systemName: banner.icon)
                    .foregroundStyle(banner.color)
                VStack(alignment: .leading, spacing: 1) {
                    Text(banner.title)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(banner.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Clear Now") { monitor.clearNow() }
                    .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            Divider()
        }
    }

    private struct BannerInfo {
        let icon: String
        let color: Color
        let title: String
        let subtitle: String
    }

    private var activeBanner: BannerInfo? {
        switch monitor.status {
        case .countdown(let s):
            BannerInfo(icon: "exclamationmark.shield.fill", color: .red,
                       title: "\(monitor.lastDetectionLabel ?? "Sensitive data") detected",
                       subtitle: "Clearing in \(s)s")
        case .postPaste(let s):
            BannerInfo(icon: "doc.on.clipboard", color: .orange,
                       title: "Pasted", subtitle: "Clearing in \(s)s")
        default:
            nil
        }
    }

    // MARK: - Primary toggles (Enabled + Launch at Login)

    private var primaryToggles: some View {
        VStack(spacing: 0) {
            toggleRow(isOn: $settings.isEnabled, label: "Enabled")
            toggleRow(isOn: $launchAtLogin, label: "Start at Login")
                .onChange(of: launchAtLogin) { _, newValue in
                    if newValue { LaunchAtLogin.enable() } else { LaunchAtLogin.disable() }
                }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Detection toggles

    private var detectionToggles: some View {
        VStack(spacing: 0) {
            toggleRow(isOn: $settings.enableCC, label: "Credit Cards")
            toggleRow(isOn: $settings.enableGovID, label: "SSN / SIN")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Timing

    private var timingSection: some View {
        VStack(spacing: 0) {
            stepperRow(label: "Clear delay", value: $settings.clearDelay, range: 5...120, unit: "s")
            stepperRow(label: "Post-paste delay", value: $settings.postPasteDelay, range: 1...10, unit: "s")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 0) {
            Button {
                NSWorkspace.shared.open(URL(string: "https://buymeacoffee.com/maferland")!)
            } label: {
                HStack {
                    Label("Support", systemImage: "heart")
                    Spacer()
                    Text("\u{2615}")
                }
            }
            .buttonStyle(MenuRowStyle())

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Label("Quit", systemImage: "xmark.circle")
                    Spacer()
                    Text("\u{2318}Q")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(MenuRowStyle())
            .keyboardShortcut("q")
        }
    }

    // MARK: - Components

    @ViewBuilder
    private var statusDot: some View {
        switch monitor.status {
        case .countdown:
            Circle().fill(.red).frame(width: 10, height: 10)
        case .postPaste:
            Circle().fill(.orange).frame(width: 10, height: 10)
        default:
            Circle()
                .fill(settings.isEnabled ? .green : .gray.opacity(0.5))
                .frame(width: 10, height: 10)
        }
    }

    private func toggleRow(isOn: Binding<Bool>, label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(CapsuleToggleStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value.wrappedValue)\(unit)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

// MARK: - AppIcon

enum AppIcon {
    static var menuBar: NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let img = NSImage(systemSymbolName: "checkmark.shield.fill",
                          accessibilityDescription: "ClipShield")?
            .withSymbolConfiguration(config)
        return img ?? NSImage()
    }
}

// MARK: - Styles

struct CapsuleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 26, height: 15)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 13, height: 13)
                    .padding(.horizontal, 1)
            }
            .onTapGesture { configuration.isOn.toggle() }
            .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
    }
}

struct MenuRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
    }
}
