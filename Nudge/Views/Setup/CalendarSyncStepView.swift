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
                // Header — Step label + title at same size, medium-bold
                VStack(spacing: 4) {
                    Text("Step 1")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Sync Your Calendar!")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 56)
                .padding(.bottom, 32)

                // Toggle rows — glossy cards
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
        .background(glossyCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "7A92A5").opacity(0.18), radius: 12, x: 0, y: 5)
        .shadow(color: Color.white.opacity(0.9), radius: 1, x: 0, y: -1)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
    }

    private var glossyCard: some View {
        ZStack {
            Color.cardSurface
            LinearGradient(
                colors: [Color.white.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
