import SwiftUI

private enum NudgeState {
    case idle, active, complete, readyConfirmed
}

struct NudgesView: View {
    @StateObject private var repo = EventRepository.shared
    @StateObject private var presetStore = PresetStore.shared
    @State private var timeNow = Date()
    @State private var nudgeState: NudgeState = .idle

    private let primaryText   = Color(hex: "1A2A36")
    private let secondaryText = Color(hex: "8A9FAF")
    private let accentColor   = Color.nudgeButton
    private let ringDiameter: CGFloat = 230
    private let ringLineWidth: CGFloat = 18  // 1.5× previous 12px

    private let timerGradient = LinearGradient(
        colors: [Color(hex: "B5CCE0"), Color(hex: "3D6178")],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if let active = repo.activeEvent(now: timeNow) {
                    eventContent(active)
                } else {
                    idleView
                }
            }
            .navigationTitle("Nudges")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { CalendarService.shared.refresh(); syncState() }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            timeNow = date; syncState()
        }
    }

    // MARK: - State Sync

    private func syncState() {
        guard let active = repo.activeEvent(now: timeNow) else {
            if nudgeState != .idle { nudgeState = .idle }
            return
        }
        let cps = CheckpointEngine.checkpoints(for: active, presets: presetStore.presets)
        let allDone = cps.allSatisfy { $0.at <= timeNow }
        if nudgeState == .idle      { nudgeState = allDone ? .complete : .active }
        else if nudgeState == .active && allDone { withAnimation { nudgeState = .complete } }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 8) {
            Text("No Active Events")
                .font(.albertSans(20, weight: .semibold))
                .foregroundColor(secondaryText)
            Text("When you have an event in its prep window,\nyour nudge will appear here.")
                .font(.albertSans(14))
                .foregroundColor(secondaryText.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -40)
    }

    // MARK: - Unified event shell (consistent layout for all non-idle states)

    private func eventContent(_ event: NudgeEvent) -> some View {
        let cps       = CheckpointEngine.checkpoints(for: event, presets: presetStore.presets)
        let completed = cps.filter { $0.at <= timeNow }.count
        let progress  = timeProgress(event: event)
        let next      = CheckpointEngine.nextCheckpoint(cps, now: timeNow)
        let urgency   = UrgencyMessages.messageForProgress(progress, variant: completed)

        return VStack(spacing: 0) {
            // ── Header (fixed) ──────────────────────────────────
            HStack {
                Text(event.title)
                    .font(.albertSans(15, weight: .semibold))
                    .foregroundColor(primaryText)
                Spacer()
                Text(formatTime(event.startDate))
                    .font(.albertSans(14))
                    .foregroundColor(secondaryText)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
            .padding(.bottom, 10)

            // ── Urgency / state label (fixed height) ─────────────
            Group {
                switch nudgeState {
                case .complete:
                    Text("Nudges Complete")
                        .font(.albertSans(22, weight: .bold))
                        .foregroundColor(primaryText)
                case .readyConfirmed:
                    Text("You're Ready!")
                        .font(.albertSans(22, weight: .bold))
                        .foregroundColor(primaryText)
                default:
                    Text(urgency)
                        .font(.albertSans(22, weight: .bold))
                        .foregroundColor(primaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 24)

            // ── Ring (always same position) ──────────────────────
            ZStack {
                switch nudgeState {
                case .active:
                    ringView(progress: progress, label: "Next nudge in...", centerContent: {
                        if let n = next {
                            CountdownView(target: n.at)
                                .font(.albertSans(40, weight: .bold))
                                .foregroundStyle(timerGradient)
                        }
                    })
                case .complete:
                    ringView(progress: 1.0, label: "nudges", centerContent: {
                        VStack(spacing: 2) {
                            Text("complete")
                                .font(.albertSans(16, weight: .semibold))
                                .foregroundColor(primaryText)
                            Text("00:00")
                                .font(.albertSans(26, weight: .bold))
                                .foregroundColor(accentColor)
                        }
                    })
                case .readyConfirmed:
                    ringView(progress: 1.0, label: "", centerContent: {
                        Text("Great Job!")
                            .font(.albertSans(20, weight: .bold))
                            .foregroundColor(primaryText)
                    })
                default:
                    ringView(progress: progress, label: "Next nudge in...", centerContent: {
                        EmptyView()
                    })
                }

                // Checkpoint time labels around the ring
                if nudgeState == .active || nudgeState == .complete {
                    checkpointLabelsAround(cps, event: event, completed: completed)
                }
            }
            .frame(width: ringDiameter + 80, height: ringDiameter + 80)

            // ── Bottom section (different per state, but same top anchor) ─
            VStack(spacing: 0) {
                switch nudgeState {
                case .active:
                    activeBottomSection(cps: cps, completed: completed, event: event)
                case .complete:
                    completeBottomSection(event: event)
                case .readyConfirmed:
                    readyConfirmedBottomSection
                default:
                    EmptyView()
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Ring

    private func ringView<C: View>(
        progress: Double,
        label: String,
        @ViewBuilder centerContent: () -> C
    ) -> some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.12), lineWidth: ringLineWidth)
                .frame(width: ringDiameter, height: ringDiameter)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "B5CCE0"), Color(hex: "3D6178")],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + max(progress, 0.001) * 360)
                    ),
                    style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                )
                .frame(width: ringDiameter, height: ringDiameter)
                .mask(
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                )
                .animation(.linear(duration: 1), value: progress)

            VStack(spacing: 6) {
                if !label.isEmpty {
                    Text(label)
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "4A6B85"))  // darker blue
                }
                centerContent()
            }
        }
    }

    // MARK: - Checkpoint labels around ring (equal angular spacing)

    private func checkpointLabelsAround(_ cps: [Checkpoint], event: NudgeEvent, completed: Int) -> some View {
        let n = cps.count
        let r = ringDiameter / 2 + 36  // just outside the ring stroke
        let step = n > 1 ? (2 * Double.pi / Double(n)) : 0

        return ZStack {
            ForEach(Array(cps.enumerated()), id: \.offset) { idx, cp in
                // Evenly distribute labels clockwise starting from top
                let angle = -Double.pi / 2 + Double(idx) * step
                let x = r * cos(angle)
                let y = r * sin(angle)
                let isDone = cp.at <= timeNow

                Text(shortTime(cp.at))
                    .font(.albertSans(11, weight: isDone ? .semibold : .regular))
                    .foregroundColor(isDone ? accentColor : secondaryText.opacity(0.7))
                    .offset(x: x, y: y)
            }
        }
    }

    // MARK: - Bottom sections

    private func activeBottomSection(cps: [Checkpoint], completed: Int, event: NudgeEvent) -> some View {
        VStack(spacing: 0) {
            alarmProgressBar(cps: cps, completed: completed, timeProgress: timeProgress(event: event))
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)

            actionButtons(event: event)
        }
    }

    private func completeBottomSection(event: NudgeEvent) -> some View {
        VStack(spacing: 20) {
            Text("Are you ready to go?")
                .font(.albertSans(18, weight: .semibold))
                .foregroundColor(primaryText)
                .padding(.top, 20)

            HStack(spacing: 16) {
                Button("No") { nudgeState = .active }
                    .font(.albertSans(16, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())

                Button("Yes!") {
                    withAnimation { nudgeState = .readyConfirmed }
                    markReady(event)
                }
                .font(.albertSans(16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accentColor)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
        }
    }

    private var readyConfirmedBottomSection: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)
            Button("Misclicked? Go back") {
                withAnimation { nudgeState = .complete }
            }
            .font(.albertSans(14))
            .foregroundColor(secondaryText)
        }
    }

    private func actionButtons(event: NudgeEvent) -> some View {
        VStack(spacing: 0) {
            Button("I'm Ready") { markReady(event) }
                .font(.albertSans(17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 200)
                .frame(height: 52)
                .background(accentColor)
                .clipShape(Capsule())
                .padding(.bottom, 12)

            Button("Cancel Event") { cancelEvent(event) }
                .font(.albertSans(14))
                .foregroundColor(Color(hex: "ABABAB"))
        }
    }

    // MARK: - Gradient progress bar with dashed interval lines

    private func alarmProgressBar(cps: [Checkpoint], completed: Int, timeProgress: Double) -> some View {
        let total = cps.count
        return VStack(alignment: .leading, spacing: 8) {
            Text("Alarm Progress")
                .font(.albertSans(12))
                .foregroundColor(primaryText)

            GeometryReader { geo in
                let w = geo.size.width
                let fillW = w * CGFloat(timeProgress)

                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor.opacity(0.12))
                        .frame(height: 15)

                    // Gradient fill
                    NudgeProgressGradient()
                        .frame(width: max(fillW, 0), height: 15)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Dashed vertical lines at intermediate checkpoints
                    if total > 1 {
                        ForEach(1..<total, id: \.self) { idx in
                            let x = w * CGFloat(idx) / CGFloat(total)
                            Path { p in
                                p.move(to: CGPoint(x: x, y: 0))
                                p.addLine(to: CGPoint(x: x, y: 15))
                            }
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2.5, 2]))
                            .foregroundColor(Color.black.opacity(0.25))
                        }
                    }
                }
            }
            .frame(height: 15)

            // Time labels precisely under each dashed line
            if total > 1 {
                GeometryReader { geo in
                    let w = geo.size.width
                    ForEach(1..<total, id: \.self) { idx in
                        let x = w * CGFloat(idx) / CGFloat(total)
                        Text(shortTime(cps[idx].at))
                            .font(.albertSans(10))
                            .foregroundColor(idx < completed ? accentColor : secondaryText)
                            .fixedSize()
                            .position(x: x, y: 6)
                    }
                }
                .frame(height: 12)
            }
        }
    }

    // MARK: - Helpers

    private func timeProgress(event: NudgeEvent) -> Double {
        let prepMins = event.prepMinutes(using: presetStore.presets)
        let prepStart = event.startDate.addingTimeInterval(-Double(prepMins) * 60)
        let totalSecs = event.startDate.timeIntervalSince(prepStart)
        guard totalSecs > 0 else { return 0 }
        return min(max(timeNow.timeIntervalSince(prepStart) / totalSecs, 0), 1)
    }

    private func markReady(_ event: NudgeEvent) {
        CheckpointScheduler.shared.dismissActiveEvent(event)
    }

    private func cancelEvent(_ event: NudgeEvent) {
        CheckpointScheduler.shared.dismissActiveEvent(event)
        withAnimation { nudgeState = .idle }
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }

    private func shortTime(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: d)
    }
}

// MARK: - Countdown

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
