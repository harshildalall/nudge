import Foundation
import EventKit
import Combine

/// Bridges EKEvent + CustomEventsStore + EventOverlayStore + PresetStore into NudgeEvents for the UI.
final class EventRepository: ObservableObject {
    static let shared = EventRepository()

    @Published private(set) var nudgeEvents: [NudgeEvent] = []
    private let calendar = CalendarService.shared
    private let customStore = CustomEventsStore.shared
    private let overlayStore = EventOverlayStore.shared
    private let presetStore = PresetStore.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        calendar.$events
            .combineLatest(customStore.$events, overlayStore.$overrides, presetStore.$presets)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ekEvents, customEvents, _, _ in
                self?.rebuild(ekEvents: ekEvents, customEvents: customEvents)
            }
            .store(in: &cancellables)
    }

    private func rebuild(ekEvents: [EKEvent], customEvents: [NudgeEvent]) {
        let fromCalendar: [NudgeEvent] = ekEvents.compactMap { ek in
            guard let start = ek.startDate, let end = ek.endDate else { return nil }
            let id = ek.eventIdentifier ?? UUID().uuidString
            let ov = overlayStore.overlay(for: id)
            let presetId = ov?.presetId ?? inferPresetId(from: ek)
            return NudgeEvent(
                id: id,
                title: ek.title ?? "Event",
                startDate: start,
                endDate: end,
                location: ek.location,
                presetId: presetId,
                prepEnabled: ov?.prepEnabled ?? true,
                prepMinutesOverride: ov?.prepMinutesOverride,
                checkpointsOverride: ov?.checkpointsOverride,
                alarmSoundOverride: ov?.alarmSoundOverride,
                completedCheckpoints: ov?.completedCheckpoints ?? 0
            )
        }
        // Apply overlays to custom events too so edits, toggles, and progress updates are reflected.
        let fromCustom: [NudgeEvent] = customEvents.map { event in
            let ov = overlayStore.overlay(for: event.id)
            return NudgeEvent(
                id: event.id,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                presetId: ov?.presetId ?? event.presetId,
                prepEnabled: ov?.prepEnabled ?? event.prepEnabled,
                prepMinutesOverride: ov?.prepMinutesOverride ?? event.prepMinutesOverride,
                checkpointsOverride: ov?.checkpointsOverride ?? event.checkpointsOverride,
                alarmSoundOverride: ov?.alarmSoundOverride ?? event.alarmSoundOverride,
                completedCheckpoints: ov?.completedCheckpoints ?? event.completedCheckpoints
            )
        }
        let merged = (fromCalendar + fromCustom).sorted { $0.startDate < $1.startDate }
        nudgeEvents = merged
    }

    private func inferPresetId(from event: EKEvent) -> UUID? {
        let title = (event.title ?? "").lowercased()
        for preset in presetStore.presets {
            if title.contains(preset.name.lowercased()) { return preset.id }
        }
        return presetStore.presets.first?.id
    }

    func togglePrep(for event: NudgeEvent) {
        overlayStore.setPrepEnabled(!event.prepEnabled, eventId: event.id)
    }

    func updateOverlay(for event: NudgeEvent, prepMinutes: Int?, checkpoints: Int?, alarmSound: String?, presetId: UUID?) {
        var ov = overlayStore.overlay(for: event.id) ?? EventOverlayStore.EventOverlay(
            prepEnabled: event.prepEnabled,
            presetId: event.presetId,
            prepMinutesOverride: nil,
            checkpointsOverride: nil,
            alarmSoundOverride: nil,
            completedCheckpoints: event.completedCheckpoints
        )
        ov.presetId = presetId
        ov.prepMinutesOverride = prepMinutes
        ov.checkpointsOverride = checkpoints
        ov.alarmSoundOverride = alarmSound
        overlayStore.setOverlay(ov, eventId: event.id)
    }

    func activeEvent(now: Date = Date()) -> NudgeEvent? {
        let presets = presetStore.presets
        return nudgeEvents.first { event in
            guard event.prepEnabled else { return false }
            let prepMins = event.prepMinutes(using: presets)
            let prepStart = event.startDate.addingTimeInterval(-Double(prepMins) * 60)
            // Allow 5-minute grace period after event start so events set to "now" still appear.
            let activeEnd = event.startDate.addingTimeInterval(5 * 60)
            return now >= prepStart && now < activeEnd
        }
    }

    func addCustomEvent(_ event: NudgeEvent) {
        customStore.add(event)
        overlayStore.setOverlay(EventOverlayStore.EventOverlay(
            prepEnabled: event.prepEnabled,
            presetId: event.presetId,
            prepMinutesOverride: event.prepMinutesOverride,
            checkpointsOverride: event.checkpointsOverride,
            alarmSoundOverride: event.alarmSoundOverride,
            completedCheckpoints: 0
        ), eventId: event.id)
    }

    func deleteEvent(_ event: NudgeEvent) {
        if event.id.hasPrefix("custom-") {
            customStore.remove(id: event.id)
        }
        overlayStore.removeOverlay(eventId: event.id)
    }

    func eventsGroupedByDate() -> [(String, [NudgeEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        let grouped = Dictionary(grouping: nudgeEvents) { e -> String in
            Calendar.current.isDateInToday(e.startDate) ? "Today, \(formatter.string(from: e.startDate))" : (Calendar.current.isDateInTomorrow(e.startDate) ? "Tomorrow, \(formatter.string(from: e.startDate))" : formatter.string(from: e.startDate))
        }
        let order = ["Today", "Tomorrow"] + (1...14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) }.map { formatter.string(from: $0) }
        return grouped.sorted { a, b in
            let ai = order.firstIndex(where: { a.key.contains($0) }) ?? 999
            let bi = order.firstIndex(where: { b.key.contains($0) }) ?? 999
            if ai != bi { return ai < bi }
            return a.key < b.key
        }.map { ($0.key, $0.value.sorted { $0.startDate < $1.startDate }) }
    }
}
