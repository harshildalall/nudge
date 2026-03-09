import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image("NudgeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 225, height: 225)
                        .blendMode(.multiply)

                    Text("Nudge")
                        .font(.albertSans(28, weight: .bold))
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
