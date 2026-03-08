//
//  NudgeWidgetExtension.swift
//  NudgeWidgetExtension
//

import WidgetKit
import SwiftUI
import AppIntents


struct WidgetEventModel {
    let eventType: String
    let eventName: String
    let eventStartTime: Date
    let checkpointTimes: [Date]
    let currentCheckpointIndex: Int
    let nextCheckpointAt: Date?
    let urgencyMessage: String

    var totalCheckpoints: Int { checkpointTimes.count }

    static var idle: WidgetEventModel {
        WidgetEventModel(
            eventType: "–",
            eventName: "No active event",
            eventStartTime: Date(),
            checkpointTimes: [],
            currentCheckpointIndex: 0,
            nextCheckpointAt: nil,
            urgencyMessage: "Open Nudge to set up an event."
        )
    }
}

struct NudgeWidgetPayload: Codable {
    let eventType: String
    let eventName: String
    let eventStartTime: Date
    let checkpointTimes: [Date]
    let currentCheckpointIndex: Int
    let nextCheckpointAt: Date?
    let urgencyMessage: String
}

func loadEventModel() -> WidgetEventModel {
    guard let defaults = UserDefaults(suiteName: nudgeAppGroupID),
          let data = defaults.data(forKey: "nudgeWidgetData"),
          let decoded = try? JSONDecoder().decode(NudgeWidgetPayload.self, from: data) else {
        return .idle
    }
    return WidgetEventModel(
        eventType: decoded.eventType,
        eventName: decoded.eventName,
        eventStartTime: decoded.eventStartTime,
        checkpointTimes: decoded.checkpointTimes,
        currentCheckpointIndex: decoded.currentCheckpointIndex,
        nextCheckpointAt: decoded.nextCheckpointAt,
        urgencyMessage: decoded.urgencyMessage
    )
}

// MARK: - Timeline Provider

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let model: WidgetEventModel
    let currentCheckpointIndex: Int
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: .init(), model: .idle, currentCheckpointIndex: 0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let model = loadEventModel()
        return SimpleEntry(date: Date(), configuration: configuration, model: model, currentCheckpointIndex: model.currentCheckpointIndex)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let model = loadEventModel()
        let now = Date()
        var entries: [SimpleEntry] = []

        if model.checkpointTimes.isEmpty {
            entries.append(SimpleEntry(date: now, configuration: configuration, model: model, currentCheckpointIndex: 0))
            return Timeline(entries: entries, policy: .after(now.addingTimeInterval(15 * 60)))
        }

        for (index, time) in model.checkpointTimes.enumerated() {
            let entryDate = max(time, now)
            entries.append(SimpleEntry(date: entryDate, configuration: configuration, model: model, currentCheckpointIndex: index))
            if index == 0 && time > now {
                entries.insert(SimpleEntry(date: now, configuration: configuration, model: model, currentCheckpointIndex: model.currentCheckpointIndex), at: 0)
            }
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Entry View

struct NudgeWidgetExtensionEntryView: View {
    var entry: Provider.Entry

    private var progress: Double {
        let times = entry.model.checkpointTimes
        guard times.count > 1 else { return entry.currentCheckpointIndex == 0 ? 0 : 1 }
        guard let first = times.first, let last = times.last, last > first else { return 0 }
        let now = entry.date
        if now <= first { return 0 }
        if now >= last { return 1 }
        guard let segIdx = times.indices.last(where: { times[$0] <= now && $0 < times.count - 1 }) else { return 0 }
        let segStart = times[segIdx]
        let segEnd = times[segIdx + 1]
        let frac = now.timeIntervalSince(segStart) / segEnd.timeIntervalSince(segStart)
        let base = Double(segIdx) / Double(times.count - 1)
        return min(max(base + frac / Double(times.count - 1), 0), 1)
    }

    private var progressLabel: String {
        let total = entry.model.totalCheckpoints
        guard total > 0 else { return "–" }
        let current = min(entry.currentCheckpointIndex + 1, total)
        return "\(current)/\(total)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Text(entry.model.urgencyMessage)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            if entry.model.totalCheckpoints > 0 {
                progressSection
            }

            dismissButton
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color(red: 0.88, green: 0.95, blue: 0.97), for: .widget)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.model.eventType.uppercased())
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(entry.model.eventName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTime(entry.model.eventStartTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                if entry.model.totalCheckpoints > 0 {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Progress")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(progressLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: geo.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private var dismissButton: some View {
        Button(intent: DismissNudgeIntent()) {
            Text("Ready")
                .font(.caption2)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(Color.white)
                )
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}

// MARK: - Widget

struct NudgeWidgetExtension: Widget {
    let kind: String = "NudgeWidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            NudgeWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Nudge")
        .description("Shows your current prep checkpoint progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    NudgeWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, configuration: .init(), model: .idle, currentCheckpointIndex: 0)
}
