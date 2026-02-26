import SwiftUI
import AppKit
import os

private let logger = Logger(subsystem: "com.maferland.clipshield", category: "App")

@main
struct ClipShieldApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = ClipboardMonitor()
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = AppIcon.menuBar
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 240, height: 400)
        popover.behavior = .transient
        let hostingController = NSHostingController(
            rootView: MenuBarView(monitor: monitor, settings: monitor.settings)
        )
        hostingController.view.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = hostingController

        monitor.start()
        logger.info("ClipShield started")
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
