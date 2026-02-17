import Foundation
import Combine

/// User-created events (not from calendar). Persisted locally and merged with calendar events.
final class CustomEventsStore: ObservableObject {
    static let shared = CustomEventsStore()

    @Published private(set) var events: [NudgeEvent] = []
    private let key = "nudge_custom_events"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NudgeEvent].self, from: data) else { return }
        events = decoded.filter { $0.id.hasPrefix("custom-") }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func add(_ event: NudgeEvent) {
        var e = event
        if !e.id.hasPrefix("custom-") {
            e = NudgeEvent(
                id: "custom-\(UUID().uuidString)",
                title: e.title,
                startDate: e.startDate,
                endDate: e.endDate,
                location: e.location,
                presetId: e.presetId,
                prepEnabled: e.prepEnabled,
                prepMinutesOverride: e.prepMinutesOverride,
                checkpointsOverride: e.checkpointsOverride,
                alarmSoundOverride: e.alarmSoundOverride,
                completedCheckpoints: 0
            )
        }
        events.append(e)
        save()
    }

    func update(_ event: NudgeEvent) {
        guard event.id.hasPrefix("custom-") else { return }
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
            save()
        }
    }

    func remove(id: String) {
        events.removeAll { $0.id == id }
        save()
    }

    func event(byId id: String) -> NudgeEvent? {
        events.first { $0.id == id }
    }
}
