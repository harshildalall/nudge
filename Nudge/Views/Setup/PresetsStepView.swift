import SwiftUI

struct PresetsStepView: View {
    let onBack: () -> Void
    let onNext: () -> Void

    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        ZStack {
            NudgeBackground()

            VStack(spacing: 0) {
                HStack {
                    NudgeBackButton(action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Header — same size & weight as CalendarSync step
                VStack(spacing: 4) {
                    Text("Step 2")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Set Nudge Presets")
                        .font(.albertSans(24, weight: .semibold))
                        .foregroundColor(Color(hex: "1A2A36"))
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Preset rows — glossy cards
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
                .font(.system(size: 22, weight: .light))
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
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "C0D0DC"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .background(glossyCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: "7A92A5").opacity(0.18), radius: 12, x: 0, y: 5)
        .shadow(color: Color.white.opacity(0.9), radius: 1, x: 0, y: -1)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
        )
        .sheet(isPresented: $showEdit) {
            EditPresetView(preset: preset)
        }
    }

    private var glossyCard: some View {
        ZStack {
            Color.cardSurface
            LinearGradient(
                colors: [Color.white.opacity(0.55), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
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
