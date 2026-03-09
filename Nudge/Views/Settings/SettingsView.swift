import SwiftUI

struct SettingsView: View {
    @StateObject private var presetStore = PresetStore.shared
    @StateObject private var calendar = CalendarService.shared
    @State private var googleOn = false
    @State private var appleOn = false
    @State private var outlookOn = false
    @State private var showEditPreset: EventPreset?
    @State private var alarmSound = "Glowy"

    private let soundOptions = ["Glowy", "Rush", "Gentle"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // MARK: Presets Section
                        sectionHeader("Presets")
                        VStack(spacing: 10) {
                            ForEach(presetStore.presets) { preset in
                                SettingsPresetCard(preset: preset) {
                                    showEditPreset = preset
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // MARK: Synced Calendars Section
                        sectionHeader("Synced Calendars")
                        VStack(spacing: 10) {
                            SettingsToggleCard(label: "Google Calendar", icon: "globe", isOn: $googleOn)
                            SettingsToggleCard(label: "Apple Calendar", icon: "applelogo", isOn: $appleOn)
                                .onChange(of: appleOn) { _, new in
                                    if new {
                                        Task { _ = await calendar.requestAccess(); calendar.fetchUpcomingEvents() }
                                    }
                                }
                            SettingsToggleCard(label: "Outlook Calendar", icon: "envelope.fill", isOn: $outlookOn)
                        }
                        .padding(.horizontal, 16)

                        // MARK: Alarm Sound Section
                        sectionHeader("Alarm Sound")
                        VStack(spacing: 0) {
                            ForEach(Array(soundOptions.enumerated()), id: \.offset) { idx, option in
                                Button(action: { alarmSound = option }) {
                                    HStack {
                                        Text(option)
                                            .font(.albertSans(16))
                                            .foregroundColor(Color(hex: "2C3E50"))
                                        Spacer()
                                        if alarmSound == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(Color.nudgeButton)
                                        } else {
                                            Circle()
                                                .stroke(Color(hex: "C0D0DC"), lineWidth: 1.5)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                }
                                if idx < soundOptions.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 18)
                                }
                            }
                        }
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
                        .padding(.horizontal, 16)

                        // MARK: Reset
                        Button("Reset presets to defaults") {
                            presetStore.resetToDefaults()
                        }
                        .font(.albertSans(14))
                        .foregroundColor(Color.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
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
                        .padding(.horizontal, 16)

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 16)
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.albertSans(13, weight: .semibold))
            .foregroundColor(Color(hex: "8A9FAF"))
            .textCase(.uppercase)
            .padding(.horizontal, 20)
            .padding(.bottom, -6)
    }
}

// MARK: - Preset Card

private struct SettingsPresetCard: View {
    let preset: EventPreset
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: resolvedIcon(preset.iconName))
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color.nudgeButton)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.albertSans(16, weight: .bold))
                    .foregroundColor(Color(hex: "1A2A36"))
                HStack(spacing: 12) {
                    Text("Prep: \(preset.defaultPrepMinutes) min")
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "8A9FAF"))
                    Text("Alarms: \(preset.numberOfCheckpoints)")
                        .font(.albertSans(12))
                        .foregroundColor(Color(hex: "8A9FAF"))
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "C0D0DC"))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
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

    private func resolvedIcon(_ name: String) -> String {
        let map: [String: String] = [
            "graduationcap": "graduationcap",
            "party.popper": "party.popper",
            "doc.text": "doc.text",
            "person.2": "person.2",
            "star": "star",
            "dumbbell": "dumbbell",
            "briefcase": "briefcase"
        ]
        return map[name.lowercased()] ?? "calendar"
    }
}

// MARK: - Toggle Card

private struct SettingsToggleCard: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color.nudgeButton)
                .frame(width: 24)

            Text(label)
                .font(.albertSans(16))
                .foregroundColor(Color(hex: "2C3E50"))

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.nudgeButton)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
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
}
