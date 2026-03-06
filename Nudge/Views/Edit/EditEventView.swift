import SwiftUI
import WidgetKit

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var repo = EventRepository.shared
    @StateObject private var presetStore = PresetStore.shared
    let event: NudgeEvent

    @State private var title: String = ""
    @State private var selectedPresetId: UUID?
    @State private var prepMinutes: Double = 30
    @State private var addBuffer = false
    @State private var numberOfCheckpoints: Int = 3
    @State private var alarmSoundId: String = "Rush"
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)

    private let soundOptions = ["Glowy", "Rush", "Gentle", "Upload Your Own"]
    private var isCustomEvent: Bool { event.id.hasPrefix("custom-") }

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Name") {
                    HStack {
                        if isCustomEvent {
                            TextField("Event name", text: $title)
                        } else {
                            Text(title)
                                .foregroundColor(Theme.secondary)
                        }
                        Image(systemName: "pencil")
                            .foregroundColor(isCustomEvent ? Theme.secondary : Color.clear)
                    }
                }
                if isCustomEvent {
                    Section("Date & Time") {
                        DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                            .tint(Theme.accent)
                        DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                            .tint(Theme.accent)
                    }
                } else {
                    Section("Date & Time") {
                        LabeledContent("Start", value: formatDateTime(event.startDate))
                        LabeledContent("End", value: formatDateTime(event.endDate))
                    }
                    .foregroundColor(Theme.secondary)
                }
                Section("Event Type") {
                    HStack {
                        Picker("", selection: $selectedPresetId) {
                            ForEach(presetStore.presets) { p in
                                Text(p.name).tag(p.id as UUID?)
                            }
                        }
                        .labelsHidden()
                        Spacer()
                        Image(systemName: "pencil")
                            .foregroundColor(Theme.secondary)
                    }
                }
                Section {
                    prepTimeSection
                } header: { Text("Prep Time") } footer: {
                    Text("Select time before event to start alarms.")
                        .font(Theme.caption2)
                }
                Section("Number of Alarms") {
                    alarmCountButtons
                }
                Section("Alarm Sound") {
                    ForEach(soundOptions, id: \.self) { id in
                        Button(action: { alarmSoundId = id }) {
                            HStack {
                                Text(id)
                                Spacer()
                                if alarmSoundId == id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .padding(.vertical, 4)
                            .background(alarmSoundId == id ? Theme.accent.opacity(0.12) : Color.clear)
                            .cornerRadius(8)
                        }
                        .foregroundColor(Theme.primary)
                    }
                }
                if isCustomEvent {
                    Section {
                        Button("Delete event", role: .destructive) {
                            repo.deleteEvent(event)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Changes") {
                        save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                title = event.title
                startDate = event.startDate
                endDate = event.endDate
                selectedPresetId = event.presetId ?? presetStore.presets.first?.id
                alarmSoundId = event.alarmSoundOverride ?? "Rush"
                numberOfCheckpoints = event.numberOfCheckpoints(using: presetStore.presets)
                // Detect buffer: if saved value is not a multiple of 15, it includes a 10-min buffer
                if let ov = EventOverlayStore.shared.overlay(for: event.id),
                   let prepOv = ov.prepMinutesOverride, prepOv > 0 {
                    if prepOv % 15 != 0 {
                        addBuffer = true
                        prepMinutes = Double(prepOv - 10)
                    } else {
                        addBuffer = false
                        prepMinutes = Double(prepOv)
                    }
                } else {
                    addBuffer = false
                    prepMinutes = Double(event.prepMinutes(using: presetStore.presets))
                }
            }
            .onChange(of: selectedPresetId) { newId in
                // When preset changes, update sliders to reflect that preset's defaults
                if let p = presetStore.presets.first(where: { $0.id == newId }) {
                    prepMinutes = Double(p.defaultPrepMinutes)
                    numberOfCheckpoints = p.numberOfCheckpoints
                    addBuffer = false
                }
            }
        }
    }

    private var prepTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prep Time")
                Spacer()
                Image(systemName: "questionmark.circle")
                    .foregroundColor(Theme.secondary)
            }
            HStack {
                Text("\(Int(prepMinutes))")
                    .font(Theme.title)
                    .foregroundColor(Theme.accent)
                    .padding(8)
                    .background(Theme.accent.opacity(0.15))
                    .clipShape(Circle())
                Spacer()
            }
            Slider(value: $prepMinutes, in: 15...120, step: 15)
                .tint(Theme.accent)
            HStack {
                Text("15")
                Spacer()
                Text("30")
                Spacer()
                Text("60")
                Spacer()
                Text("90")
                Spacer()
                Text("120")
            }
            .font(Theme.caption2)
            .foregroundColor(Theme.secondary)
            Toggle("Add 10 min buffer time", isOn: $addBuffer)
                .tint(Theme.accent)
        }
    }

    private var alarmCountButtons: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { n in
                Button(action: { numberOfCheckpoints = n }) {
                    Text("\(n)")
                        .font(Theme.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(numberOfCheckpoints == n ? Theme.accent : Color.gray.opacity(0.15))
                        .foregroundColor(numberOfCheckpoints == n ? .white : Theme.primary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func save() {
        let totalPrep = Int(prepMinutes) + (addBuffer ? 10 : 0)
        repo.updateOverlay(
            for: event,
            prepMinutes: totalPrep,
            checkpoints: numberOfCheckpoints,
            alarmSound: alarmSoundId,
            presetId: selectedPresetId
        )
        if isCustomEvent {
            let e = NudgeEvent(
                id: event.id,
                title: title,
                startDate: startDate,
                endDate: endDate,
                location: event.location,
                presetId: selectedPresetId,
                prepEnabled: event.prepEnabled,
                prepMinutesOverride: totalPrep,
                checkpointsOverride: numberOfCheckpoints,
                alarmSoundOverride: alarmSoundId,
                completedCheckpoints: event.completedCheckpoints
            )
            CustomEventsStore.shared.update(e)
        }
        // Immediately refresh the widget and scheduler so changes are visible
        CheckpointScheduler.shared.start()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
