import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "alarm")
                        .font(.system(size: 100, weight: .thin)) // SF Symbol — keep system for weight rendering
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "8FA8BC"), Color(hex: "5C7A91")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "7A92A5").opacity(0.3), radius: 16, x: 0, y: 8)

                    Text("nudge")
                        .font(.albertSans(28))
                        .foregroundColor(Color(hex: "4A6378"))
                        .tracking(1)
                }

                Spacer()

                NudgePrimaryButton(title: "Get Started") {
                    appState.completeOnboarding()
                }
                .padding(.bottom, 48)
            }
        }
    }
}
