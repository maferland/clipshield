import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private let userDefaults: UserDefaults

    @Published var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: "isEnabled") }
    }

    @Published var clearDelay: Int {
        didSet { userDefaults.set(clearDelay, forKey: "clearDelay") }
    }

    @Published var postPasteDelay: Int {
        didSet { userDefaults.set(postPasteDelay, forKey: "postPasteDelay") }
    }

    @Published var enableCC: Bool {
        didSet { userDefaults.set(enableCC, forKey: "enableCC") }
    }

    @Published var enableGovID: Bool {
        didSet { userDefaults.set(enableGovID, forKey: "enableGovID") }
    }

    var enabledPatterns: Set<PatternType> {
        var set = Set<PatternType>()
        if enableCC { set.insert(.cc) }
        if enableGovID {
            set.insert(.ssn)
            set.insert(.sin)
        }
        return set
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let defaults: [String: Any] = [
            "isEnabled": true,
            "clearDelay": 30,
            "postPasteDelay": 2,
            "enableCC": true,
            "enableGovID": true,
        ]
        userDefaults.register(defaults: defaults)

        self.isEnabled = userDefaults.bool(forKey: "isEnabled")
        self.clearDelay = userDefaults.integer(forKey: "clearDelay")
        self.postPasteDelay = userDefaults.integer(forKey: "postPasteDelay")
        self.enableCC = userDefaults.bool(forKey: "enableCC")
        self.enableGovID = userDefaults.bool(forKey: "enableGovID")
    }
}
