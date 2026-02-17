import ActivityKit
import WidgetKit
import SwiftUI

/// Lock Screen Live Activity UI. Matches mockup: event type, name, time, urgency, progress with checkpoint numbers, Done.
struct NudgeLiveActivityView: View {
    let context: ActivityViewContext<NudgeActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(context.attributes.eventType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(startTimeString(context.attributes.eventStartTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(context.attributes.eventName)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(context.state.urgencyMessage)
                .font(.subheadline)
                .foregroundColor(context.state.isLeaveNow ? .red : .primary)

            if !context.attributes.checkpointTimes.isEmpty {
                progressSection
            }

            Button(action: {}) {
                Text("Done")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var progressSection: some View {
        let progress = context.state.totalCheckpoints > 0
            ? Double(context.state.currentCheckpointIndex) / Double(context.state.totalCheckpoints)
            : 0.0
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                ForEach(1...context.state.totalCheckpoints, id: \.self) { i in
                    Text("\(i)")
                        .font(.caption2)
                        .foregroundColor(i <= context.state.currentCheckpointIndex ? Color.accentColor : .secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func startTimeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}

