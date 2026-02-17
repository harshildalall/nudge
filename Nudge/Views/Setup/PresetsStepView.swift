import SwiftUI

struct PresetsStepView: View {
    @StateObject private var presetStore = PresetStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("presets")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
                Text("step 2")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
                Text("Set prep-time presets")
                    .font(Theme.title)
                    .foregroundColor(Theme.primary)
                Text("Manage how your alarms are generated.")
                    .font(Theme.subheadline)
                    .foregroundColor(Theme.secondary)

                ForEach(presetStore.presets) { preset in
                    PresetRowView(preset: preset)
                }
            }
            .padding(20)
        }
    }
}

struct PresetRowView: View {
    let preset: EventPreset
    @State private var showEdit = false

    var body: some View {
        HStack {
            Image(systemName: iconNameForPreset(preset.iconName))
                .font(.system(size: 18))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(preset.name)
                    .font(Theme.headline)
                Text("Prep Time: \(preset.defaultPrepMinutes) min · Alarms: \(preset.numberOfCheckpoints)")
                    .font(Theme.caption2)
                    .foregroundColor(Theme.secondary)
            }
            Spacer()
            Button(action: { showEdit = true }) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.primary)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(10)
        .sheet(isPresented: $showEdit) {
            EditPresetView(preset: preset)
        }
    }

    private func iconNameForPreset(_ name: String) -> String {
        switch name.lowercased() {
        case "graduationcap": return "graduationcap"
        case "doc.text": return "doc.text"
        case "person.2": return "person.2"
        case "star": return "star"
        case "dumbbell": return "dumbbell"
        case "briefcase": return "briefcase"
        default: return "calendar"
        }
    }
}
