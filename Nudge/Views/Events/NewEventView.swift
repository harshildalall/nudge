import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var presetStore = PresetStore.shared
    @State private var title = ""
    @State private var selectedPresetId: UUID?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var prepMinutes: Double = 30
    @State private var addBuffer = false
    @State private var numberOfCheckpoints = 3
    @State private var alarmSoundId = "Rush"

    private let soundOptions = ["Glowy", "Rush", "Gentle", "Upload Your Own"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Event Name") {
                    TextField("Event name", text: $title)
                }
                Section("Event Type") {
                    Picker("Type", selection: $selectedPresetId) {
                        Text("Select…").tag(nil as UUID?)
                        ForEach(presetStore.presets) { p in
                            Text(p.name).tag(p.id as UUID?)
                        }
                    }
                }
                Section("Date & Time") {
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }
                Section {
                    prepTimeSection
                } header: { Text("Prep Time") }
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
                        }
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                selectedPresetId = presetStore.presets.first?.id
            }
        }
    }

    private var prepTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(Int(prepMinutes)) min")
                    .font(Theme.headline)
                    .foregroundColor(Theme.accent)
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

    private func saveAndDismiss() {
        let totalPrep = Int(prepMinutes) + (addBuffer ? 10 : 0)
        let event = NudgeEvent(
            id: "custom-\(UUID().uuidString)",
            title: title,
            startDate: startDate,
            endDate: endDate,
            presetId: selectedPresetId,
            prepEnabled: true,
            prepMinutesOverride: totalPrep,
            checkpointsOverride: numberOfCheckpoints,
            alarmSoundOverride: alarmSoundId,
            completedCheckpoints: 0
        )
        EventRepository.shared.addCustomEvent(event)
        CheckpointScheduler.shared.start()
        dismiss()
    }
}
