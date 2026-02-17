import Foundation
import ActivityKit

/// Live Activity attributes. Duplicate of Shared/NudgeActivityAttributes for Widget Extension target.
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
