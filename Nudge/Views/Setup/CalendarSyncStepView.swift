import SwiftUI

struct CalendarSyncStepView: View {
    let onNext: () -> Void

    @StateObject private var calendar = CalendarService.shared
    @State private var googleOn = true
    @State private var appleOn = true
    @State private var outlookOn = false

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack(spacing: 0) {
                // Header (no back button on step 1)
                VStack(spacing: 6) {
                    Text("Step 1")
                        .font(.albertSans(15))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Sync Your Calendar!")
                        .font(.albertSans(26, weight: .bold))
                        .foregroundColor(Color(hex: "1A2A36"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 56)
                .padding(.bottom, 32)

                // Toggle rows — each in its own card
                VStack(spacing: 12) {
                    CalendarToggleRow(label: "Google Calendar", isOn: $googleOn)
                    CalendarToggleRow(label: "Apple Calendar", isOn: $appleOn)
                        .onChange(of: appleOn) { _, new in
                            if new { requestCalendarAccess() }
                        }
                    CalendarToggleRow(label: "Outlook Calendar", isOn: $outlookOn)
                }
                .padding(.horizontal, 20)

                if !calendar.isAuthorized && appleOn {
                    Button("Open Settings to allow calendar access") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.albertSans(13))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }

                Spacer()

                NudgePrimaryButton(title: "Next", action: onNext)
                    .padding(.bottom, 48)
            }
        }
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

private struct CalendarToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.nudgeButton)
                .scaleEffect(0.9)
                .frame(width: 44)

            Text(label)
                .font(.albertSans(16))
                .foregroundColor(Color(hex: "2C3E50"))

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
