import SwiftUI

struct EventsListView: View {
    @StateObject private var repo = EventRepository.shared
    @StateObject private var calendar = CalendarService.shared
    @State private var showEditEvent: NudgeEvent?
    @State private var showNewEvent = false
    @State private var selectedDate = Date()
    @State private var isExpanded = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Custom header (replaces nav title)
                headerSection

                // Day circle bubbles
                dayBubblesRow
                    .padding(.bottom, 12)

                if repo.nudgeEvents.isEmpty {
                    emptyView
                } else {
                    eventsSection
                }
            }
        }
        .onAppear { calendar.refresh() }
        .sheet(item: $showEditEvent) { event in EditEventView(event: event) }
        .sheet(isPresented: $showNewEvent) { NewEventView() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dayString(selectedDate))
                    .font(.albertSans(34, weight: .bold))
                    .foregroundColor(Color.nudgeButton)
                Text(fullDateString(selectedDate))
                    .font(.albertSans(13))
                    .foregroundColor(Color(hex: "8A9FAF"))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Button(action: { showNewEvent = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.nudgeButton)
                }
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.8))
                    Text("62°F")
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "8A9FAF"))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Day Circle Bubbles

    private var dayBubblesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<14, id: \.self) { offset in
                    let d = Calendar.current.date(byAdding: .day, value: offset - 1, to: Date()) ?? Date()
                    let isSelected = Calendar.current.isDate(d, inSameDayAs: selectedDate)
                    let dateNum = Calendar.current.component(.day, from: d)
                    let letter = dayLetterFor(d)

                    Button(action: { selectedDate = d }) {
                        VStack(spacing: 5) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.nudgeButton : Color.white.opacity(0.8))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Circle().stroke(
                                            isSelected ? Color.nudgeButton : Color(hex: "D0DCE8"),
                                            lineWidth: 1.5
                                        )
                                    )
                                    .shadow(
                                        color: isSelected ? Color.nudgeButton.opacity(0.3) : Color.black.opacity(0.06),
                                        radius: isSelected ? 6 : 3, x: 0, y: 2
                                    )
                                Text("\(dateNum)")
                                    .font(.albertSans(14, weight: isSelected ? .bold : .semibold))
                                    .foregroundColor(isSelected ? .white : Color(hex: "2C3E50"))
                            }
                            Text(letter)
                                .font(.albertSans(10))
                                .foregroundColor(isSelected ? Color.nudgeButton : Color(hex: "8A9FAF"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Events section

    private var eventsSection: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Section header with expand arrow
                HStack {
                    Text("Events")
                        .font(.albertSans(13, weight: .semibold))
                        .foregroundColor(Color(hex: "8A9FAF"))
                        .textCase(.uppercase)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "8A9FAF"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)

                if eventsForSelectedDate.isEmpty {
                    Spacer().frame(height: 40)
                    Text("No events on this day")
                        .font(.albertSans(16))
                        .foregroundColor(Color(hex: "8A9FAF"))
                        .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 10) {
                        ForEach(eventsForSelectedDate) { event in
                            if isExpanded {
                                EventCardExpanded(
                                    event: event,
                                    onTogglePrep: { repo.togglePrep(for: event) },
                                    onTap: { showEditEvent = event }
                                )
                            } else {
                                EventCardMinimized(
                                    event: event,
                                    onTogglePrep: { repo.togglePrep(for: event) },
                                    onTap: { showEditEvent = event }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Helpers

    private var eventsForSelectedDate: [NudgeEvent] {
        repo.nudgeEvents.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate)
        }
    }

    private func dayLetterFor(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEEE"; return f.string(from: d)
    }
    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: d)
    }
    private func fullDateString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"; return f.string(from: d)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            ContentUnavailableView(
                "No upcoming events",
                systemImage: "calendar.badge.plus",
                description: Text("Add an event or sync your calendar in Settings.")
            )
            Button(action: { showNewEvent = true }) {
                Label("Add Event", systemImage: "plus.circle.fill")
                    .font(.albertSans(16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.nudgeButton)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Glossy card background helper

private var glossyCardBackground: some View {
    ZStack {
        Color.cardSurface
        LinearGradient(
            colors: [Color.white.opacity(0.55), Color.clear],
            startPoint: .top, endPoint: .bottom
        )
    }
}

// MARK: - Minimized Event Card

struct EventCardMinimized: View {
    let event: NudgeEvent
    let onTogglePrep: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(timeString(event.startDate))
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text(event.title)
                        .font(.albertSans(16, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                        .lineLimit(1)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { event.prepEnabled },
                    set: { _ in onTogglePrep() }
                ))
                .labelsHidden()
                .tint(Color.nudgeButton)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(glossyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "7A92A5").opacity(0.14), radius: 10, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.9), radius: 1, x: 0, y: -1)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }
}

// MARK: - Expanded Event Card

struct EventCardExpanded: View {
    let event: NudgeEvent
    let onTogglePrep: () -> Void
    let onTap: () -> Void
    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(presetTypeLabel(for: event))
                        .font(.albertSans(11, weight: .semibold))
                        .foregroundColor(Color(hex: "8A9FAF"))
                        .textCase(.uppercase)
                    Spacer()
                    Text(timeString(event.startDate))
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "8A9FAF"))
                }
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: iconName(for: event))
                        .font(.system(size: 15))
                        .foregroundColor(Color.nudgeButton)
                    Text(event.title)
                        .font(.albertSans(16, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                        .lineLimit(1)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { event.prepEnabled },
                        set: { _ in onTogglePrep() }
                    ))
                    .labelsHidden()
                    .tint(Color.nudgeButton)
                }
                let total = max(1, event.numberOfCheckpoints(using: presetStore.presets))
                let completed = event.completedCheckpoints
                HStack {
                    Text("Checkpoint Progress")
                        .font(.albertSans(11))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Spacer()
                    Text("\(completed)/\(total)")
                        .font(.albertSans(11))
                        .foregroundColor(Color(hex: "8A9FAF"))
                }
                ProgressView(value: Double(completed), total: Double(total))
                    .tint(Color.nudgeButton)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(glossyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "7A92A5").opacity(0.14), radius: 10, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.9), radius: 1, x: 0, y: -1)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.7), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func presetTypeLabel(for event: NudgeEvent) -> String {
        guard let id = event.presetId, let p = presetStore.preset(byId: id) else { return "EVENT" }
        return p.name
    }
    private func timeString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }
    private func iconName(for event: NudgeEvent) -> String {
        guard let id = event.presetId, let p = presetStore.preset(byId: id) else { return "calendar" }
        return p.iconName
    }
}
