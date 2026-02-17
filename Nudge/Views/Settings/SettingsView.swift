import SwiftUI

struct SettingsView: View {
    @StateObject private var presetStore = PresetStore.shared
    @StateObject private var calendar = CalendarService.shared
    @State private var defaultIntervalSound = "sound1"
    @State private var defaultFinalSound = "fire alarm"
    @State private var googleOn = false
    @State private var appleOn = false
    @State private var outlookOn = false
    @State private var showEditPreset: EventPreset?

    var body: some View {
        NavigationStack {
            List {
                Section("Presets") {
                    ForEach(presetStore.presets) { preset in
                        Button(action: { showEditPreset = preset }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(Theme.callout)
                                        .foregroundColor(Theme.primary)
                                    Text("Prep Time: \(preset.defaultPrepMinutes) min · \(preset.numberOfCheckpoints) alarms")
                                        .font(Theme.caption2)
                                        .foregroundColor(Theme.secondary)
                                }
                                Spacer()
                                Text("Edit")
                                    .font(Theme.caption)
                                    .foregroundColor(Theme.secondary)
                            }
                        }
                    }
                }

                Section("Calendar Sync") {
                    Toggle("Google Calendar", isOn: $googleOn)
                    Toggle("Apple Calendar", isOn: $appleOn)
                        .onChange(of: appleOn) { _, new in
                            if new { Task { _ = await calendar.requestAccess(); calendar.fetchUpcomingEvents() } }
                        }
                    Toggle("Outlook Calendar", isOn: $outlookOn)
                }

                Section("Edit Nudge Sounds") {
                    Picker("Default interval alarm sound", selection: $defaultIntervalSound) {
                        Text("sound 1").tag("sound1")
                        Text("sound 2").tag("sound2")
                        Text("sound 3").tag("sound3")
                    }
                    Picker("Default final alarm sound", selection: $defaultFinalSound) {
                        Text("fire alarm").tag("fire alarm")
                        Text("sound 1").tag("sound1")
                    }
                }

                Section {
                    Button("Reset presets to defaults", role: .destructive) {
                        presetStore.resetToDefaults()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $showEditPreset) { preset in
                EditPresetView(preset: preset)
            }
            .onAppear {
                appleOn = calendar.isAuthorized
            }
        }
    }
}
