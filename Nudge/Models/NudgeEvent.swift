import Foundation

/// Calendar-derived event with prep checkpoints (read from calendar + our overlay)
struct NudgeEvent: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var presetId: UUID?
    var prepEnabled: Bool
    /// Per-event overrides (nil = use preset)
    var prepMinutesOverride: Int?
    var checkpointsOverride: Int?
    var alarmSoundOverride: String?
    var completedCheckpoints: Int

    init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        presetId: UUID? = nil,
        prepEnabled: Bool = true,
        prepMinutesOverride: Int? = nil,
        checkpointsOverride: Int? = nil,
        alarmSoundOverride: String? = nil,
        completedCheckpoints: Int = 0
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.presetId = presetId
        self.prepEnabled = prepEnabled
        self.prepMinutesOverride = prepMinutesOverride
        self.checkpointsOverride = checkpointsOverride
        self.alarmSoundOverride = alarmSoundOverride
        self.completedCheckpoints = completedCheckpoints
    }

    func prepMinutes(using presets: [EventPreset]) -> Int {
        if let override = prepMinutesOverride { return override }
        guard let pid = presetId, let p = presets.first(where: { $0.id == pid }) else {
            return 15
        }
        return p.totalPrepMinutes
    }

    func numberOfCheckpoints(using presets: [EventPreset]) -> Int {
        if let override = checkpointsOverride { return override }
        guard let pid = presetId, let p = presets.first(where: { $0.id == pid }) else {
            return 2
        }
        return p.numberOfCheckpoints
    }
}
