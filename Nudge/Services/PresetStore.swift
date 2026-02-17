import Foundation
import Combine

final class PresetStore: ObservableObject {
    static let shared = PresetStore()

    @Published private(set) var presets: [EventPreset] = []
    private let key = "nudge_event_presets"

    init() {
        load()
        if presets.isEmpty {
            presets = Self.defaultPresets()
            save()
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([EventPreset].self, from: data) else { return }
        presets = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func update(_ preset: EventPreset) {
        if let i = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[i] = preset
        } else {
            presets.append(preset)
        }
        save()
    }

    func delete(_ preset: EventPreset) {
        presets.removeAll { $0.id == preset.id }
        save()
    }

    func preset(byId id: UUID) -> EventPreset? {
        presets.first { $0.id == id }
    }

    func resetToDefaults() {
        presets = Self.defaultPresets()
        save()
    }

    static func defaultPresets() -> [EventPreset] {
        [
            EventPreset(name: "Class", iconName: "graduationcap", defaultPrepMinutes: 15, numberOfCheckpoints: 2),
            EventPreset(name: "Exam", iconName: "doc.text", defaultPrepMinutes: 30, numberOfCheckpoints: 3),
            EventPreset(name: "Interview", iconName: "person.2", defaultPrepMinutes: 45, numberOfCheckpoints: 4),
            EventPreset(name: "Social", iconName: "star", defaultPrepMinutes: 15, numberOfCheckpoints: 2),
            EventPreset(name: "Gym", iconName: "dumbbell", defaultPrepMinutes: 20, numberOfCheckpoints: 2),
            EventPreset(name: "Work", iconName: "briefcase", defaultPrepMinutes: 15, numberOfCheckpoints: 2)
        ]
    }
}
