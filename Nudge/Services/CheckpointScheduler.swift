import Foundation
import WidgetKit

/// Schedules checkpoint notifications and updates Live Activity when in prep window.
final class CheckpointScheduler: ObservableObject {
    static let shared = CheckpointScheduler()
    private let repo = EventRepository.shared
    private let presetStore = PresetStore.shared
    private let overlayStore = EventOverlayStore.shared
    private var timer: Timer?

    func start() {
        timer?.invalidate()
        let t = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.tick()
        }
        t.tolerance = 10
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Called by "I'm Ready" or the widget's Dismiss button. Immediately ends the active session.
    func dismissActiveEvent(_ event: NudgeEvent) {
        overlayStore.setPrepEnabled(false, eventId: event.id)
        NotificationService.shared.cancelAll()
        if #available(iOS 16.1, *) { LiveActivityManager.shared.endActivity() }
        NudgeWidgetSharedStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func tick() {
        let now = Date()
        // Check if the widget's Dismiss button was tapped
        if NudgeWidgetSharedStore.isDismissRequested() {
            NudgeWidgetSharedStore.clearDismissRequest()
            if let active = repo.activeEvent(now: now) {
                dismissActiveEvent(active)
            }
            return
        }
        guard let active = repo.activeEvent(now: now) else {
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.endActivity()
            }
            NudgeWidgetSharedStore.clear()
            WidgetCenter.shared.reloadAllTimelines()
            return
        }

        let presets = presetStore.presets
        let checkpoints = CheckpointEngine.checkpoints(for: active, presets: presets)
        let upcoming = CheckpointEngine.upcomingCheckpoints(checkpoints, now: now)
        let next = CheckpointEngine.nextCheckpoint(checkpoints, now: now)
        let completed = checkpoints.filter { $0.at <= now }.count
        let typeLabel = active.presetId.flatMap { pid in presetStore.preset(byId: pid)?.name } ?? "Event"

        // Compute time-based progress for accurate urgency messages
        let prepMins = active.prepMinutes(using: presets)
        let prepStart = active.startDate.addingTimeInterval(-Double(prepMins) * 60)
        let totalSecs = active.startDate.timeIntervalSince(prepStart)
        let timeProgress = totalSecs > 0 ? min(max(now.timeIntervalSince(prepStart) / totalSecs, 0), 1) : 0

        NotificationService.shared.cancelAllForEvent(eventId: active.id)
        for cp in upcoming {
            NotificationService.shared.scheduleCheckpoint(cp, eventTitle: active.title, soundId: active.alarmSoundOverride ?? "sound1")
        }
        overlayStore.setCompletedCheckpoints(completed, eventId: active.id)

        // Write to shared App Group storage so the widget can show real data
        let urgency = UrgencyMessages.messageForProgress(timeProgress, variant: completed)
        let widgetData = NudgeWidgetData(
            eventType: typeLabel.uppercased(),
            eventName: active.title,
            eventStartTime: active.startDate,
            checkpointTimes: checkpoints.map(\.at),
            currentCheckpointIndex: completed,
            nextCheckpointAt: next?.at,
            urgencyMessage: urgency
        )
        NudgeWidgetSharedStore.write(widgetData)
        WidgetCenter.shared.reloadAllTimelines()

        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startOrUpdate(
                event: active,
                checkpoints: checkpoints,
                completed: completed,
                nextCheckpoint: next,
                eventTypeLabel: typeLabel.uppercased(),
                timeProgress: timeProgress
            )
        }
    }
}
