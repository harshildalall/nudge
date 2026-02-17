import Foundation

/// Schedules checkpoint notifications and updates Live Activity when in prep window.
final class CheckpointScheduler: ObservableObject {
    static let shared = CheckpointScheduler()
    private let repo = EventRepository.shared
    private let presetStore = PresetStore.shared
    private let overlayStore = EventOverlayStore.shared
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer?.tolerance = 10
        RunLoop.main.add(timer!, forMode: .common)
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        let now = Date()
        guard let active = repo.activeEvent(now: now) else {
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.endActivity()
            }
            return
        }

        let presets = presetStore.presets
        let checkpoints = CheckpointEngine.checkpoints(for: active, presets: presets)
        let upcoming = CheckpointEngine.upcomingCheckpoints(checkpoints, now: now)
        let next = CheckpointEngine.nextCheckpoint(checkpoints, now: now)
        let completed = checkpoints.filter { $0.at <= now }.count

        NotificationService.shared.cancelAllForEvent(eventId: active.id)
        for cp in upcoming {
            NotificationService.shared.scheduleCheckpoint(cp, eventTitle: active.title, soundId: active.alarmSoundOverride ?? "sound1")
        }
        overlayStore.setCompletedCheckpoints(completed, eventId: active.id)

        if #available(iOS 16.1, *) {
            let typeLabel = active.presetId.flatMap { pid in presetStore.preset(byId: pid)?.name } ?? "EVENT"
            LiveActivityManager.shared.startOrUpdate(
                event: active,
                checkpoints: checkpoints,
                completed: completed,
                nextCheckpoint: next,
                eventTypeLabel: typeLabel.uppercased()
            )
        }
    }
}
