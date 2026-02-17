import Foundation
import ActivityKit

/// Live Activity state for Lock Screen widget. Add this file to both Nudge and NudgeWidgetExtension targets.
struct NudgeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentCheckpointIndex: Int
        var totalCheckpoints: Int
        var nextCheckpointAt: Date?
        var urgencyMessage: String
        var isLeaveNow: Bool
    }

    var eventType: String
    var eventName: String
    var eventStartTime: Date
    var checkpointTimes: [Date]
}
