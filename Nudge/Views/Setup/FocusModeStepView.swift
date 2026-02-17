import SwiftUI

struct FocusModeStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("override focus mode")
                .font(Theme.caption2)
                .foregroundColor(Theme.secondary)
            Text("step 3 (final step)")
                .font(Theme.caption2)
                .foregroundColor(Theme.secondary)
            Text("Override Focus Mode")
                .font(Theme.title)
                .foregroundColor(Theme.primary)
            Text("So Nudge can alert you even when Focus is on:")
                .font(Theme.subheadline)
                .foregroundColor(Theme.secondary)

            VStack(alignment: .leading, spacing: 10) {
                Label("1. Go to Settings", systemImage: "gear")
                    .font(Theme.callout)
                Label("2. Notifications → Nudge → Time Sensitive", systemImage: "bell")
                    .font(Theme.callout)
                Text("Allow Time Sensitive notifications so you never miss a nudge.")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
            }
            .padding(12)

            Button(action: openSettings) {
                Text("Open Settings")
                    .font(Theme.headline)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(20)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
