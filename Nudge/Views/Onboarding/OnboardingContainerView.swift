import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var appState = AppState.shared
    @State private var page: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    let totalPages = 3

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if page < totalPages {
                onboardingPage
            } else {
                launchScreen
            }
        }
        .onAppear {
            page = 0
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                page = 0
            }
        }
    }

    private var onboardingPage: some View {
        VStack(spacing: 0) {
            Text("ONBOARDING")
                .font(Theme.largeTitle)
                .foregroundColor(Theme.primary)
            Text("onboarding")
                .font(Theme.caption2)
                .foregroundColor(Theme.secondary)

            Spacer()

            Group {
                if page == 0 {
                    Text("tired of checking the clock before you leave for an event?")
                        .multilineTextAlignment(.center)
                } else if page == 1 {
                    Text("getting distracted during your \"5 more minutes\"?")
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 12) {
                        Text("never lose track of time getting ready to leave with...")
                            .multilineTextAlignment(.center)
                        appLogoImage
                        Text("nudge")
                            .font(.system(size: 24, weight: .medium))
                    }
                }
            }
            .font(Theme.body)
            .foregroundColor(Theme.primary)
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)

            Spacer()

            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Theme.primary : Theme.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 16)

            Button(action: {
                if page < totalPages - 1 {
                    page += 1
                } else {
                    page = totalPages
                }
            }) {
                Text(page < totalPages - 1 ? "Next" : "Continue")
                    .font(Theme.headline)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.primary)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }

    private var appLogoImage: some View {
        Image("AppLogo")
            .resizable()
            .frame(width: 80, height: 80)
            .cornerRadius(18)
    }

    private var launchScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            appLogoImage
            Text("nudge")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(Theme.primary)
            Spacer()
            Button(action: {
                appState.completeOnboarding()
            }) {
                Text("Get started")
                    .font(Theme.headline)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
    }
}
