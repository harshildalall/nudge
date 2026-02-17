import Foundation
import Combine

/// Onboarding / setup completed state
final class AppState: ObservableObject {
    static let shared = AppState()

    enum Flow {
        case onboarding
        case setup
        case main
    }

    @Published var currentFlow: Flow = .onboarding
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasCompletedSetup: Bool = false

    private let onboardingKey = "nudge_onboarding_done"
    private let setupKey = "nudge_setup_done"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        hasCompletedSetup = UserDefaults.standard.bool(forKey: setupKey)
        updateFlow()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
        updateFlow()
    }

    func completeSetup() {
        hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: setupKey)
        updateFlow()
    }

    private func updateFlow() {
        if !hasCompletedOnboarding {
            currentFlow = .onboarding
        } else if !hasCompletedSetup {
            currentFlow = .setup
        } else {
            currentFlow = .main
        }
    }

    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        UserDefaults.standard.removeObject(forKey: setupKey)
        hasCompletedOnboarding = false
        hasCompletedSetup = false
        updateFlow()
    }
}
