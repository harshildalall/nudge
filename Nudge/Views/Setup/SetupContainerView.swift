import SwiftUI

private enum SetupStep { case calendarSync, presets, focusMode }

struct SetupContainerView: View {
    @StateObject private var appState = AppState.shared
    @State private var step: SetupStep = .calendarSync

    var body: some View {
        ZStack {
            switch step {
            case .calendarSync:
                CalendarSyncStepView {
                    withAnimation(.easeInOut(duration: 0.3)) { step = .presets }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .presets:
                PresetsStepView(
                    onBack: { withAnimation(.easeInOut(duration: 0.3)) { step = .calendarSync } },
                    onNext: { withAnimation(.easeInOut(duration: 0.3)) { step = .focusMode } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))

            case .focusMode:
                FocusModeStepView(
                    onBack: { withAnimation(.easeInOut(duration: 0.3)) { step = .presets } },
                    onBegin: { appState.completeSetup() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
    }
}
