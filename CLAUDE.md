# ClipShield

Native macOS menu bar app that monitors clipboard for sensitive data and auto-clears it.

## Tech
- Swift 5.9, SwiftUI, SPM (no .xcodeproj)
- macOS 14+, `MenuBarExtra` with `.menuBarExtraStyle(.window)`
- Swift Testing for unit tests
- No external dependencies

## Architecture
- `ClipShield/Detector.swift` — Pattern detection (CC with Luhn, SSN, SIN). Fully testable.
- `ClipShield/ClipboardMonitor.swift` — 0.5s polling via `NSPasteboard.changeCount`, countdown + auto-clear
- `ClipShield/ClipboardProvider.swift` — Protocol for testability (real + mock providers)
- `ClipShield/SettingsStore.swift` — UserDefaults preferences
- `ClipShield/MenuBarView.swift` — SwiftUI popover menu bar UI
- `ClipShield/ClipShieldApp.swift` — App entry point + AppDelegate
- `ClipShield/LaunchAtLogin.swift` — SMAppService integration

## Dev
```sh
swift build          # debug build
swift test           # run tests
make build           # release build
make install         # build + install to /Applications
```

## Key patterns
- `NSPasteboard.changeCount` for O(1) change detection (no content diff until change confirmed)
- `ClipboardProvider` protocol enables mock injection in tests
- `@MainActor` on `ClipboardMonitor` — all state updates are synchronous, no `DispatchQueue.main.async`
- `org.nspasteboard.ConcealedType` set on re-write to hint clipboard managers
