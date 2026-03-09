import SwiftUI

struct NudgesView: View {
    @StateObject private var repo = EventRepository.shared
    @StateObject private var presetStore = PresetStore.shared
    @State private var timeNow = Date()

    var body: some View {
        NavigationStack {
            Group {
                if let active = repo.activeEvent(now: timeNow) {
                    activeNudgeView(active)
                } else {
                    idleView
                }
            }
            .navigationTitle("Nudges")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            CalendarService.shared.refresh()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            timeNow = date
        }
    }

    private func activeNudgeView(_ event: NudgeEvent) -> some View {
        let checkpoints = CheckpointEngine.checkpoints(for: event, presets: presetStore.presets)
        let next = CheckpointEngine.nextCheckpoint(checkpoints, now: timeNow)
        let completed = checkpoints.filter { $0.at <= timeNow }.count
        let ringProgress = timeProgress(event: event)
        let urgencyMessage = UrgencyMessages.messageForProgress(ringProgress, variant: completed)

        return ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text(event.title)
                        .font(Theme.headline)
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Text(formatTime(event.startDate))
                        .font(Theme.callout)
                        .foregroundColor(Theme.secondary)
                }
                .padding(.horizontal, 20)

                Text(urgencyMessage)
                    .font(Theme.title)
                    .foregroundColor(ringProgress >= 0.75 ? Theme.urgency : Theme.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                if let n = next {
                    circularCountdown(next: n, progress: ringProgress)
                }

                alarmProgressSection(checkpoints: checkpoints, completed: completed, timeProgress: ringProgress)
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Button("I'm Ready") {
                        markReady(event)
                    }
                    .font(Theme.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent)
                    .cornerRadius(12)

                    Button("Cancel Event") {
                        markReady(event)
                    }
                    .font(Theme.callout)
                    .foregroundColor(Theme.secondary)
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: - Circular Countdown

    private func circularCountdown(next: Checkpoint, progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 180, height: 180)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text("next nudge in...")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
                CountdownView(target: next.at)
                    .font(.albertSans(32, weight: .medium))
                    .foregroundColor(Theme.primary)
            }
        }
        .padding(.vertical, 16)
    }

    // MARK: - Alarm Progress Bar

    private func alarmProgressSection(checkpoints: [Checkpoint], completed: Int, timeProgress: Double) -> some View {
        let total = checkpoints.count
        let barProgress = timeProgress

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Alarm Progress")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondary)
                Spacer()
                Text("\(completed)/\(total)")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * barProgress, height: 8)
                    // Checkpoint dot markers positioned proportionally
                    if total > 1 {
                        ForEach(Array(checkpoints.enumerated()), id: \.offset) { idx, _ in
                            let fraction = Double(idx) / Double(total - 1)
                            Circle()
                                .fill(idx < completed ? Theme.accent : Color.white)
                                .overlay(Circle().stroke(idx < completed ? Theme.accent : Color.gray.opacity(0.5), lineWidth: 1.5))
                                .frame(width: 12, height: 12)
                                .offset(x: geo.size.width * fraction - 6)
                        }
                    }
                }
            }
            .frame(height: 12)

            // Time labels spread evenly across full width
            if !checkpoints.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(checkpoints.enumerated()), id: \.offset) { idx, cp in
                        Text(shortTime(cp.at))
                            .font(Theme.caption2)
                            .foregroundColor(idx < completed ? Theme.accent : Theme.secondary)
                        if idx < checkpoints.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        ContentUnavailableView(
            "No active events",
            systemImage: "bell.slash",
            description: Text("When you have an event in its prep window, your nudge will appear here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    /// Smooth 0…1 progress based on elapsed time through the full prep window.
    private func timeProgress(event: NudgeEvent) -> Double {
        let prepMins = event.prepMinutes(using: presetStore.presets)
        let prepStart = event.startDate.addingTimeInterval(-Double(prepMins) * 60)
        let totalSecs = event.startDate.timeIntervalSince(prepStart)
        guard totalSecs > 0 else { return 0 }
        let elapsed = timeNow.timeIntervalSince(prepStart)
        return min(max(elapsed / totalSecs, 0), 1)
    }

    private func markReady(_ event: NudgeEvent) {
        CheckpointScheduler.shared.dismissActiveEvent(event)
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }

    private func shortTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: d)
    }
}

struct CountdownView: View {
    let target: Date
    @State private var remaining: String = ""

    var body: some View {
        Text(remaining)
            .onAppear { update() }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in update() }
    }

    private func update() {
        let now = Date()
        guard target > now else { remaining = "0:00"; return }
        let interval = target.timeIntervalSince(now)
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        remaining = String(format: "%d:%02d", m, s)
    }
}
