import SwiftUI

struct PresetsStepView: View {
    let onBack: () -> Void
    let onNext: () -> Void

    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    NudgeBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Header
                VStack(spacing: 6) {
                    Text("Step 2")
                        .font(.albertSans(15))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Set Nudge Presets")
                        .font(.albertSans(26, weight: .bold))
                        .foregroundColor(Color(hex: "1A2A36"))
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Preset rows
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(presetStore.presets) { preset in
                            PresetRowView(preset: preset)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                NudgePrimaryButton(title: "Next", action: onNext)
                    .padding(.bottom, 48)
            }
        }
    }
}

struct PresetRowView: View {
    let preset: EventPreset
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName(for: preset.iconName))
                .font(.albertSans(22, weight: .light))
                .foregroundColor(Color(hex: "7A92A5"))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.albertSans(16, weight: .bold))
                    .foregroundColor(Color(hex: "1A2A36"))

                HStack(spacing: 14) {
                    Text("Prep Time: \(preset.defaultPrepMinutes) min")
                        .font(.albertSans(13))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Alarms: \(preset.numberOfCheckpoints)")
                        .font(.albertSans(13))
                        .foregroundColor(Color(hex: "8A9FAF"))
                }
            }

            Spacer()

            Button(action: { showEdit = true }) {
                Image(systemName: "pencil")
                    .font(.albertSans(15))
                    .foregroundColor(Color(hex: "C0D0DC"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showEdit) {
            EditPresetView(preset: preset)
        }
    }

    private func iconName(for name: String) -> String {
        switch name.lowercased() {
        case "graduationcap": return "graduationcap"
        case "party.popper":  return "party.popper"
        case "doc.text":      return "doc.text"
        case "person.2":      return "person.2"
        case "star":          return "star"
        case "dumbbell":      return "dumbbell"
        case "briefcase":     return "briefcase"
        default:              return "calendar"
        }
    }
}
