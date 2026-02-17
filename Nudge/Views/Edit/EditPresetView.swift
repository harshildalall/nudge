import SwiftUI

struct EditPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var presetStore = PresetStore.shared
    let preset: EventPreset

    @State private var name: String = ""
    @State private var prepMinutes: Double = 15
    @State private var addBuffer = false
    @State private var numberOfCheckpoints: Int = 2
    @State private var alarmSoundId: String = "Rush"

    private let soundOptions = ["Glowy", "Rush", "Gentle", "Upload Your Own"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Preset Name") {
                    HStack {
                        TextField("Name", text: $name)
                        Image(systemName: "pencil")
                            .foregroundColor(Theme.secondary)
                    }
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
                            .padding(.vertical, 4)
                            .background(alarmSoundId == id ? Theme.accent.opacity(0.12) : Color.clear)
                            .cornerRadius(8)
                        }
                        .foregroundColor(Theme.primary)
                    }
                }
            }
            .navigationTitle("Edit Preset")
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
                name = preset.name
                prepMinutes = Double(preset.defaultPrepMinutes)
                numberOfCheckpoints = preset.numberOfCheckpoints
                alarmSoundId = preset.alarmSoundId == "sound1" ? "Glowy" : (preset.alarmSoundId == "sound2" ? "Rush" : (preset.alarmSoundId == "sound3" ? "Gentle" : "Rush"))
                addBuffer = preset.bufferMinutes >= 10
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
                Text("30")
                Spacer()
                Text("60")
                Spacer()
                Text("90")
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
        let soundMap = ["Glowy": "sound1", "Rush": "sound2", "Gentle": "sound3", "Upload Your Own": "sound3"]
        var updated = preset
        updated.name = name
        updated.defaultPrepMinutes = Int(prepMinutes)
        updated.numberOfCheckpoints = numberOfCheckpoints
        updated.bufferMinutes = addBuffer ? 10 : 0
        updated.alarmSoundId = soundMap[alarmSoundId] ?? "sound2"
        presetStore.update(updated)
    }
}
