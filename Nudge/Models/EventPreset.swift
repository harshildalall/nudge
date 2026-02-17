import Foundation

/// Default preparation behavior by event type (Class, Social, Work, etc.)
struct EventPreset: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var iconName: String
    var defaultPrepMinutes: Int
    var numberOfCheckpoints: Int
    var bufferMinutes: Int // 0, 10, or 20
    var alarmSoundId: String
    var notificationIntensity: NotificationIntensity

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "calendar",
        defaultPrepMinutes: Int = 15,
        numberOfCheckpoints: Int = 2,
        bufferMinutes: Int = 0,
        alarmSoundId: String = "sound1",
        notificationIntensity: NotificationIntensity = .medium
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.defaultPrepMinutes = min(120, max(5, defaultPrepMinutes))
        self.numberOfCheckpoints = min(5, max(1, numberOfCheckpoints))
        self.bufferMinutes = bufferMinutes
        self.alarmSoundId = alarmSoundId
        self.notificationIntensity = notificationIntensity
    }

    var totalPrepMinutes: Int { defaultPrepMinutes + bufferMinutes }
}

enum NotificationIntensity: String, Codable, CaseIterable {
    case calm
    case medium
    case urgent
}
