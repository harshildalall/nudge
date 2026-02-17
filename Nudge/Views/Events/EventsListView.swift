import SwiftUI

struct EventsListView: View {
    @StateObject private var repo = EventRepository.shared
    @StateObject private var calendar = CalendarService.shared
    @State private var searchText = ""
    @State private var showEditEvent: NudgeEvent?
    @State private var showNewEvent = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Group {
                if repo.nudgeEvents.isEmpty {
                    emptyView
                } else {
                    eventListContent
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { calendar.refresh() }) {
                            Image(systemName: "magnifyingglass")
                        }
                        Button(action: { showNewEvent = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
            .sheet(item: $showEditEvent) { event in
                EditEventView(event: event)
            }
            .sheet(isPresented: $showNewEvent) {
                NewEventView()
            }
        }
        .onAppear {
            calendar.refresh()
        }
    }

    private var eventListContent: some View {
        VStack(spacing: 0) {
            daySelector
            List {
                ForEach(repo.eventsGroupedByDate(), id: \.0) { sectionTitle, events in
                    Section(sectionTitle) {
                        ForEach(events) { event in
                            EventRowView(
                                event: event,
                                onTogglePrep: { repo.togglePrep(for: event) },
                                onTap: { showEditEvent = event }
                            )
                            .listRowBackground(Color(.systemGroupedBackground))
                            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var daySelector: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<7, id: \.self) { offset in
                        let d = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        let isSelected = Calendar.current.isDate(d, inSameDayAs: selectedDate)
                        let dayLetter = dayLetterFor(d)
                        let dateNum = Calendar.current.component(.day, from: d)
                        Button(action: { selectedDate = d }) {
                            VStack(spacing: 4) {
                                Text(dayLetter)
                                    .font(Theme.caption)
                                Text("\(dateNum)")
                                    .font(Theme.callout)
                                    .fontWeight(isSelected ? .semibold : .regular)
                            }
                            .frame(width: 36)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.gray.opacity(0.25) : Color.clear)
                            .cornerRadius(20)
                        }
                        .foregroundColor(Theme.primary)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            HStack {
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Theme.secondary)
                }
                Spacer()
                VStack(alignment: .center, spacing: 2) {
                    Text(dayString(selectedDate))
                        .font(Theme.headline)
                    Text(fullDateString(selectedDate))
                        .font(Theme.caption2)
                        .foregroundColor(Theme.secondary)
                }
                Spacer()
                Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Theme.background)
    }

    private func dayLetterFor(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: d)
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: d)
    }

    private func fullDateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f.string(from: d)
    }

    private var calendarPermissionView: some View {
        VStack(spacing: 12) {
            Text("Calendar access needed")
                .font(Theme.headline)
            Text("Enable calendar in Setup or Settings to see events.")
                .font(Theme.subheadline)
                .foregroundColor(Theme.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "No upcoming events",
                systemImage: "calendar.badge.plus",
                description: Text("Add an event or sync your calendar in Settings.")
            )
            Button(action: { showNewEvent = true }) {
                Label("Add Event", systemImage: "plus.circle.fill")
                    .font(Theme.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

}

struct EventRowView: View {
    let event: NudgeEvent
    let onTogglePrep: () -> Void
    let onTap: () -> Void
    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(presetTypeLabel(for: event))
                        .font(Theme.caption2)
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Text(timeString(event.startDate))
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondary)
                }
                HStack(alignment: .center) {
                    Image(systemName: iconName(for: event))
                        .font(.system(size: 16))
                        .foregroundColor(Theme.secondary)
                    Text(event.title)
                        .font(Theme.headline)
                        .foregroundColor(Theme.primary)
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { event.prepEnabled },
                        set: { _ in onTogglePrep() }
                    ))
                    .labelsHidden()
                    .tint(Theme.accent)
                }
                Text("Checkpoint Progress \(event.completedCheckpoints)/\(event.numberOfCheckpoints(using: presetStore.presets))")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
                ProgressView(value: Double(event.completedCheckpoints), total: Double(max(1, event.numberOfCheckpoints(using: presetStore.presets))))
                    .tint(Theme.accent)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func presetTypeLabel(for event: NudgeEvent) -> String {
        guard let id = event.presetId, let p = presetStore.preset(byId: id) else { return "EVENT" }
        return p.name.uppercased()
    }

    private func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private func iconName(for event: NudgeEvent) -> String {
        guard let id = event.presetId, let p = presetStore.preset(byId: id) else { return "calendar" }
        return p.iconName
    }
}
