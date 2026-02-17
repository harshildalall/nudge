import SwiftUI

@main
struct NudgeApp: App {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        Task {
            _ = await NotificationService.shared.requestAuthorization()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, new in
            if new == .active {
                CalendarService.shared.refresh()
                CheckpointScheduler.shared.start()
            } else if new == .background {
                CheckpointScheduler.shared.stop()
            }
        }
    }
}
