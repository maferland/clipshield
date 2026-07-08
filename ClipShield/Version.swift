import Foundation

// Read from the bundle's Info.plist (populated at package time by scripts/package_app.sh).
// Falls back to "dev" when run outside an app bundle (e.g. `swift run`).
let appVersion: String = {
    guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
          !version.isEmpty else {
        return "dev"
    }
    return version.hasPrefix("v") ? version : "v\(version)"
}()
