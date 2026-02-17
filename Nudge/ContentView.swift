import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        Group {
            switch appState.currentFlow {
            case .onboarding:
                OnboardingContainerView()
            case .setup:
                SetupContainerView()
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: appState.currentFlow)
    }
}
