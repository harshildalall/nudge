import Foundation

// MARK: - Urgency Messages

enum UrgencyMessages {
    private static let early = [
        "Let's get up now…",
        "Time to start getting ready.",
        "Get off your phone.",
        "Start now or you'll regret it later.",
        "Okay, start getting ready.",
        "You should probably start.",
        "Start now. Just saying.",
        "Time to move.",
        "Don't wait.",
        "Let's get moving.",
        "Time to get rolling."
    ]

    private static let mid = [
        "You're pushing it.",
        "You don't have extra time.",
        "Still sitting?",
        "You said you'd be on time this time.",
        "Okay. Now actually move.",
        "Clock's ticking.",
        "Don't do the 5-minute thing.",
        "Remember your plan.",
        "Don't self sabotage.",
        "Time's moving, let's move too."
    ]

    private static let final = [
        "Leave.",
        "Go. Now.",
        "Out the door.",
        "GO.",
        "Leave NOW or you'll be late.",
        "No extra minutes.",
        "Head out now.",
        "Time's up, let's go.",
        "Ready? Go!"
    ]

    /// Returns a deterministic urgency message for a given checkpoint index and total count.
    static func message(checkpointIndex: Int, total: Int) -> String {
        guard total > 0 else { return early[0] }
        if checkpointIndex >= total - 1 {
            return final[checkpointIndex % final.count]
        } else if checkpointIndex == 0 {
            return early[0 % early.count]
        } else {
            return mid[(checkpointIndex - 1) % mid.count]
        }
    }
}

// MARK: - Shared Widget Store

/// Data written by the main app and read by the widget extension via App Group shared UserDefaults.
struct NudgeWidgetData: Codable {
    let eventType: String
    let eventName: String
    let eventStartTime: Date
    let checkpointTimes: [Date]
    let currentCheckpointIndex: Int
    let nextCheckpointAt: Date?
    let urgencyMessage: String
}

/// IMPORTANT: This App Group identifier must exactly match what you configured in
/// Xcode → Signing & Capabilities for BOTH the Nudge and NudgeWidgetExtension targets.
let nudgeAppGroupID = "group.com.harshildalal.nudge"

enum NudgeWidgetSharedStore {
    private static let key = "nudgeWidgetData"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: nudgeAppGroupID)
    }

    static func write(_ data: NudgeWidgetData) {
        guard let defaults = sharedDefaults,
              let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }

    static func read() -> NudgeWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(NudgeWidgetData.self, from: data) else { return nil }
        return decoded
    }

    static func clear() {
        sharedDefaults?.removeObject(forKey: key)
    }

    // MARK: Dismiss flag (written by widget Dismiss button, read by main app on next tick)
    private static let dismissKey = "nudge_dismiss_requested"

    static func requestDismiss() {
        sharedDefaults?.set(true, forKey: dismissKey)
    }

    static func isDismissRequested() -> Bool {
        sharedDefaults?.bool(forKey: dismissKey) ?? false
    }

    static func clearDismissRequest() {
        sharedDefaults?.removeObject(forKey: dismissKey)
    }

    // MARK: Buffer flag (written by widget Add Buffer button, read by main app on next tick)
    private static let bufferKey = "nudge_buffer_requested"

    static func requestBuffer() {
        sharedDefaults?.set(true, forKey: bufferKey)
    }

    static func isBufferRequested() -> Bool {
        sharedDefaults?.bool(forKey: bufferKey) ?? false
    }

    static func clearBufferRequest() {
        sharedDefaults?.removeObject(forKey: bufferKey)
    }
}
