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
    @State private var alarmSoundId = "Glowy"

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
                    Text("New Event")
                        .font(.albertSans(17, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.clear)

                ScrollView {
                    VStack(spacing: 14) {
                        // Event Name
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EVENT NAME")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                TextField("Event name", text: $title)
                                    .font(.albertSans(16))
                                    .foregroundColor(Color(hex: "1A2A36"))
                            }
                        }

                        // Event Type
                        formCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EVENT TYPE")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                HStack {
                                    Picker("", selection: $selectedPresetId) {
                                        Text("Select…").tag(nil as UUID?)
                                        ForEach(presetStore.presets) { p in
                                            Text(p.name).tag(p.id as UUID?)
                                        }
                                    }
                                    .labelsHidden()
                                    .font(.albertSans(16))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "C0D0DC"))
                                }
                            }
                        }

                        // Date & Time
                        formCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("DATE & TIME")
                                    .font(.albertSans(11, weight: .semibold))
                                    .foregroundColor(Color(hex: "8A9FAF"))
                                DatePicker("Start", selection: $startDate)
                                    .font(.albertSans(15))
                                    .tint(Color.nudgeButton)
                                Divider()
                                DatePicker("End", selection: $endDate, in: startDate...)
                                    .font(.albertSans(15))
                                    .tint(Color.nudgeButton)
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

                // Save button
                VStack {
                    Button("Save Event") {
                        saveAndDismiss()
                    }
                    .font(.albertSans(17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(title.isEmpty ? Color.nudgeButton.opacity(0.5) : Color.nudgeButton)
                    .clipShape(Capsule())
                    .disabled(title.isEmpty)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .padding(.top, 12)
                }
                .background(Color.clear)
            }
        }
        .onAppear {
            if let first = presetStore.presets.first {
                selectedPresetId = first.id
                prepMinutes = Double(first.defaultPrepMinutes)
                numberOfCheckpoints = first.numberOfCheckpoints
            }
        }
        .onChange(of: selectedPresetId) { _, newId in
            if let p = presetStore.presets.first(where: { $0.id == newId }) {
                prepMinutes = Double(p.defaultPrepMinutes)
                numberOfCheckpoints = p.numberOfCheckpoints
                addBuffer = false
            }
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
