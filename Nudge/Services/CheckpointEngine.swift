import Foundation

/// Generates checkpoints from event start time and preset (or overrides).
struct CheckpointEngine {
    static func checkpoints(
        for event: NudgeEvent,
        presets: [EventPreset]
    ) -> [Checkpoint] {
        let prepMins = event.prepMinutes(using: presets)
        let count = event.numberOfCheckpoints(using: presets)
        guard prepMins > 0, count > 0 else { return [] }
        let prepStart = event.startDate.addingTimeInterval(-Double(prepMins) * 60)
        var result: [Checkpoint] = []
        for i in 0..<count {
            let fraction = count == 1 ? 1.0 : Double(i) / Double(count - 1)
            let at = prepStart.addingTimeInterval(fraction * Double(prepMins) * 60)
            let isLeaveNow = (i == count - 1)
            result.append(Checkpoint(id: UUID(), at: at, index: i, total: count, isLeaveNow: isLeaveNow))
        }
        return result
    }

    /// Checkpoints that are in the future (not yet fired).
    static func upcomingCheckpoints(_ all: [Checkpoint], now: Date = Date()) -> [Checkpoint] {
        all.filter { $0.at > now }
    }

    /// Next single checkpoint after now.
    static func nextCheckpoint(_ all: [Checkpoint], now: Date = Date()) -> Checkpoint? {
        upcomingCheckpoints(all, now: now).first
    }

    /// Progress 0...1 for the prep window.
    static func progress(completed: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}
