import SwiftUI

struct NudgesView: View {
    @StateObject private var repo = EventRepository.shared
    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        NavigationStack {
            Group {
                if let active = repo.activeEvent() {
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
    }

    private func activeNudgeView(_ event: NudgeEvent) -> some View {
        let checkpoints = CheckpointEngine.checkpoints(for: event, presets: presetStore.presets)
        let next = CheckpointEngine.nextCheckpoint(checkpoints)
        let progress = CheckpointEngine.progress(completed: event.completedCheckpoints, total: event.numberOfCheckpoints(using: presetStore.presets))
        return ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text(event.title)
                        .font(Theme.headline)
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Text(startTimeString(event.startDate))
                        .font(Theme.callout)
                        .foregroundColor(Theme.secondary)
                }
                .padding(.horizontal, 20)

                Text("Let's get up now...")
                    .font(Theme.title)
                    .foregroundColor(Theme.primary)
                    .frame(maxWidth: .infinity)

                if let n = next {
                    circularCountdown(next: n, progress: progress, checkpoints: checkpoints)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Alarm Progress")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondary)
                    HStack {
                        ForEach(checkpoints) { cp in
                            Text(timeString(cp.at))
                                .font(Theme.caption2)
                                .foregroundColor(Theme.secondary)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.accent)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
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

                    Button("Cancel Event") { }
                        .font(Theme.callout)
                        .foregroundColor(Theme.secondary)
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 24)
        }
    }

    private func circularCountdown(next: Checkpoint, progress: Double, checkpoints: [Checkpoint]) -> some View {
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
                    .font(.system(size: 32, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.primary)
            }
        }
        .padding(.vertical, 16)
    }

    private var idleView: some View {
        ContentUnavailableView(
            "No active events",
            systemImage: "bell.slash",
            description: Text("When you have an event in its prep window, your nudge will appear here.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startTimeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: d)
    }

    private func markReady(_ event: NudgeEvent) {
        let total = event.numberOfCheckpoints(using: presetStore.presets)
        EventOverlayStore.shared.setCompletedCheckpoints(total, eventId: event.id)
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
        guard target > now else {
            remaining = "0:00"
            return
        }
        let interval = target.timeIntervalSince(now)
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        remaining = String(format: "%d:%02d", m, s)
    }
}
