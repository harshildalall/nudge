import SwiftUI

struct CalendarSyncStepView: View {
    @StateObject private var calendar = CalendarService.shared
    @State private var googleOn = false
    @State private var appleOn = false
    @State private var outlookOn = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SETUP")
                .font(Theme.caption2)
                .foregroundColor(Theme.secondary)
            Text("calendar sync")
                .font(Theme.title)
                .foregroundColor(Theme.primary)
            Text("step 1")
                .font(Theme.caption2)
                .foregroundColor(Theme.secondary)
            Text("Sync your calendar!")
                .font(Theme.headline)

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Google Calendar", isOn: $googleOn)
                    .font(Theme.callout)
                    .tint(Theme.primary)
                Toggle("Apple Calendar", isOn: $appleOn)
                    .font(Theme.callout)
                    .tint(Theme.primary)
                    .onChange(of: appleOn) { _, new in
                        if new { requestCalendarAccess() }
                    }
                Toggle("Outlook Calendar", isOn: $outlookOn)
                    .font(Theme.callout)
                    .tint(Theme.primary)
            }
            .padding(.top, 4)

            if !calendar.isAuthorized && appleOn {
                Button("Open Settings to allow calendar access") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(Theme.subheadline)
                .foregroundColor(Theme.accent)
            }

            Spacer()
        }
        .padding(20)
        .onAppear {
            if calendar.isAuthorized { appleOn = true }
        }
    }

    private func requestCalendarAccess() {
        Task {
            _ = await calendar.requestAccess()
            calendar.fetchUpcomingEvents()
        }
    }
}
