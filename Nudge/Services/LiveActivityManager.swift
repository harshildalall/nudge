import Foundation
import ActivityKit

@available(iOS 16.1, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    func startOrUpdate(event: NudgeEvent, checkpoints: [Checkpoint], completed: Int, nextCheckpoint: Checkpoint?, eventTypeLabel: String = "EVENT") {
        let urgency = UrgencyMessages.message(checkpointIndex: completed, total: checkpoints.count)
        let state = NudgeActivityAttributes.ContentState(
            currentCheckpointIndex: completed,
            totalCheckpoints: checkpoints.count,
            nextCheckpointAt: nextCheckpoint?.at,
            urgencyMessage: urgency,
            isLeaveNow: nextCheckpoint?.isLeaveNow ?? false
        )
        let attributes = NudgeActivityAttributes(
            eventType: eventTypeLabel,
            eventName: event.title,
            eventStartTime: event.startDate,
            checkpointTimes: checkpoints.map(\.at)
        )
        let content = ActivityContent(state: state, staleDate: nil)

        Task { @MainActor in
            if let current = Activity<NudgeActivityAttributes>.activities.first(where: { $0.attributes.eventName == event.title && $0.attributes.eventStartTime == event.startDate }) {
                await current.update(content)
            } else {
                _ = try? Activity.request(attributes: attributes, content: content, pushType: nil)
            }
        }
    }

    func endActivity() {
        Task { @MainActor in
            let finalState = NudgeActivityAttributes.ContentState(
                currentCheckpointIndex: 0,
                totalCheckpoints: 0,
                nextCheckpointAt: nil,
                urgencyMessage: "",
                isLeaveNow: false
            )
            let content = ActivityContent(state: finalState, staleDate: nil)
            for activity in Activity<NudgeActivityAttributes>.activities {
                await activity.end(content, dismissalPolicy: .immediate)
            }
        }
    }
}
