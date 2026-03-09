import SwiftUI

struct EditPresetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var presetStore = PresetStore.shared
    let preset: EventPreset

    @State private var name: String = ""
    @State private var prepMinutes: Double = 15
    @State private var addBuffer = false
    @State private var numberOfCheckpoints: Int = 2
    @State private var alarmSoundId: String = "Glowy"

    private let soundOptions = ["Glowy", "Rush", "Gentle", "Upload Your Own"]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button("Cancel") { dismiss() }
                            .font(.albertSans(15))
                            .foregroundColor(Color(hex: "8A9FAF"))
                        Spacer()
                    }
                    Text("Edit Preset")
                        .font(.albertSans(17, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.clear)

                ScrollView {
                    VStack(spacing: 14) {
                        // Preset Name
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PRESET NAME")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                HStack {
                                    TextField("Name", text: $name)
                                        .font(.albertSans(16))
                                        .foregroundColor(Color(hex: "1A2A36"))
                                    Image(systemName: "pencil")
                                        .foregroundColor(Color(hex: "C0D0DC"))
                                }
                            }
                        }

                        // Prep Time
                        formCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PREP TIME")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))

                                SliderWithBubble(value: $prepMinutes, range: 15...120, step: 15)

                                Toggle("Add 10 min buffer time", isOn: $addBuffer)
                                    .font(.albertSans(14))
                                    .tint(Color.nudgeButton)
                            }
                        }

                        // Number of Alarms
                        formCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("NUMBER OF ALARMS")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                HStack(spacing: 8) {
                                    ForEach(1...5, id: \.self) { n in
                                        Button(action: { numberOfCheckpoints = n }) {
                                            Text("\(n)")
                                                .font(.albertSans(15, weight: .semibold))
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(numberOfCheckpoints == n ? Color.nudgeButton : Color(hex: "EDF1F5"))
                                                .foregroundColor(numberOfCheckpoints == n ? .white : Color(hex: "2C3E50"))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        // Alarm Sound
                        formCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ALARM SOUND")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                VStack(spacing: 0) {
                                    ForEach(Array(soundOptions.enumerated()), id: \.offset) { idx, option in
                                        Button(action: { alarmSoundId = option }) {
                                            HStack {
                                                Text(option)
                                                    .font(.albertSans(15))
                                                    .foregroundColor(Color(hex: "2C3E50"))
                                                Spacer()
                                                if alarmSoundId == option {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(Color.nudgeButton)
                                                } else {
                                                    Circle()
                                                        .stroke(Color(hex: "C0D0DC"), lineWidth: 1.5)
                                                        .frame(width: 20, height: 20)
                                                }
                                            }
                                            .padding(.vertical, 12)
                                        }
                                        if idx < soundOptions.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        }

                        Spacer().frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }

                // Save Changes pill button
                VStack {
                    Button("Save Changes") {
                        save()
                        dismiss()
                    }
                    .font(.albertSans(17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.nudgeButton)
                    .clipShape(Capsule())
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .padding(.top, 12)
                }
                .background(Color.clear)
            }
        }
        .onAppear {
            name = preset.name
            prepMinutes = Double(preset.defaultPrepMinutes)
            numberOfCheckpoints = preset.numberOfCheckpoints
            alarmSoundId = preset.alarmSoundId == "sound1" ? "Glowy" : (preset.alarmSoundId == "sound2" ? "Rush" : (preset.alarmSoundId == "sound3" ? "Gentle" : "Glowy"))
            addBuffer = preset.bufferMinutes >= 10
        }
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    Color.cardSurface
                    LinearGradient(colors: [Color.white.opacity(0.55), Color.clear], startPoint: .top, endPoint: .bottom)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color(hex: "7A92A5").opacity(0.18), radius: 12, x: 0, y: 5)
            .shadow(color: Color.white.opacity(0.9), radius: 1, x: 0, y: -1)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.7), lineWidth: 1))
    }

    private func save() {
        let soundMap = ["Glowy": "sound1", "Rush": "sound2", "Gentle": "sound3", "Upload Your Own": "sound3"]
        var updated = preset
        updated.name = name
        updated.defaultPrepMinutes = Int(prepMinutes)
        updated.numberOfCheckpoints = numberOfCheckpoints
        updated.bufferMinutes = addBuffer ? 10 : 0
        updated.alarmSoundId = soundMap[alarmSoundId] ?? "sound1"
        presetStore.update(updated)
    }
}

// MARK: - Slider with floating bubble

struct SliderWithBubble: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(spacing: 4) {
            // Bubble indicator above thumb
            GeometryReader { geo in
                let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
                let thumbX = normalized * (geo.size.width - 28) + 14
                ZStack {
                    Text("\(Int(value)) min")
                        .font(.albertSans(12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.nudgeButton)
                        .clipShape(Capsule())
                        .position(x: thumbX, y: 14)
                }
            }
            .frame(height: 28)

            Slider(value: $value, in: range, step: step)
                .tint(Color.nudgeButton)

            HStack {
                Text("\(Int(range.lowerBound))")
                Spacer()
                Text("\(Int((range.lowerBound + range.upperBound) / 2))")
                Spacer()
                Text("\(Int(range.upperBound))")
            }
            .font(.albertSans(11))
            .foregroundColor(Color(hex: "8A9FAF"))
        }
    }
}
