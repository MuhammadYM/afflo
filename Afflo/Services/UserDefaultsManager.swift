import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    private init() {}

    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey)
        }
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
