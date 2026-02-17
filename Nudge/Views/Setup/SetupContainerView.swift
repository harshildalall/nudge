import SwiftUI

struct SetupContainerView: View {
    @StateObject private var appState = AppState.shared
    @State private var step: Int = 0

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Group {
                    if step == 0 { CalendarSyncStepView() }
                    else if step == 1 { PresetsStepView() }
                    else { FocusModeStepView() }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: nextOrFinish) {
                    Text(step == 2 ? "Finish" : "Next")
                        .font(Theme.headline)
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    step -= 1
                }
                .font(Theme.callout)
                .foregroundColor(Theme.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func nextOrFinish() {
        if step < 2 {
            step += 1
        } else {
            appState.completeSetup()
        }
    }
}
