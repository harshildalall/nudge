import Foundation
import Combine

/// Per-event overrides and prep enabled state (synced with calendar IDs).
final class EventOverlayStore: ObservableObject {
    static let shared = EventOverlayStore()

    @Published private(set) var overrides: [String: EventOverlay] = [:]
    private let key = "nudge_event_overlays"

    struct EventOverlay: Codable {
        var prepEnabled: Bool
        var presetId: UUID?
        var prepMinutesOverride: Int?
        var checkpointsOverride: Int?
        var alarmSoundOverride: String?
        var completedCheckpoints: Int
    }

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: EventOverlay].self, from: data) else { return }
        overrides = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(overrides) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func setPrepEnabled(_ enabled: Bool, eventId: String) {
        if overrides[eventId] != nil {
            overrides[eventId]?.prepEnabled = enabled
        } else {
            overrides[eventId] = EventOverlay(prepEnabled: enabled, presetId: nil, prepMinutesOverride: nil, checkpointsOverride: nil, alarmSoundOverride: nil, completedCheckpoints: 0)
        }
        save()
    }

    func setOverlay(_ overlay: EventOverlay, eventId: String) {
        overrides[eventId] = overlay
        save()
    }

    func overlay(for eventId: String) -> EventOverlay? {
        overrides[eventId]
    }

    func setCompletedCheckpoints(_ count: Int, eventId: String) {
        if overrides[eventId] != nil {
            overrides[eventId]?.completedCheckpoints = count
        } else {
            overrides[eventId] = EventOverlay(prepEnabled: true, presetId: nil, prepMinutesOverride: nil, checkpointsOverride: nil, alarmSoundOverride: nil, completedCheckpoints: count)
        }
        save()
    }

    func removeOverlay(eventId: String) {
        overrides.removeValue(forKey: eventId)
        save()
    }
}
