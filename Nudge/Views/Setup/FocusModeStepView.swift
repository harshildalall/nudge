import SwiftUI

struct FocusModeStepView: View {
    let onBack: () -> Void
    let onBegin: () -> Void

    private let steps = ["Go to settings", "Override focus mode"]

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    NudgeBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Header — same size & weight as other steps
                VStack(spacing: 4) {
                    Text("Step 3")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Override Focus Mode")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)

                // Numbered steps — center the block, keep circles/text aligned
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                        HStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "7A92A5"))
                                    .frame(width: 38, height: 38)
                                Text("\(index + 1)")
                                    .font(.albertSans(16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text(text)
                                .font(.albertSans(17))
                                .foregroundColor(Color(hex: "2C3E50"))
                        }
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 28)

                Spacer()

                NudgePrimaryButton(title: "Begin", action: onBegin)
                    .padding(.bottom, 48)
            }
        }
    }
}
