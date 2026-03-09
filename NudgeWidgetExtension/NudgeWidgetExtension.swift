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

// MARK: - Gradient helpers for widget

// Darker light-blue start so gradient reads clearly on the light background
private let widgetTextGradient = LinearGradient(
    colors: [Color(red: 0.48, green: 0.62, blue: 0.74), Color(red: 0.24, green: 0.38, blue: 0.47)],
    startPoint: .top,
    endPoint: .bottom
)

private let widgetBarGradient = LinearGradient(
    colors: [Color(red: 0.48, green: 0.62, blue: 0.74), Color(red: 0.24, green: 0.38, blue: 0.47)],
    startPoint: .leading,
    endPoint: .trailing
)

private let widgetAccent    = Color(red: 0.48, green: 0.57, blue: 0.65)
private let widgetPrimary   = Color(red: 0.10, green: 0.16, blue: 0.21)
private let widgetSecondary = Color(red: 0.54, green: 0.62, blue: 0.69)

// MARK: - Entry View

struct NudgeWidgetExtensionEntryView: View {
    var entry: Provider.Entry

    private var progress: Double {
        let times = entry.model.checkpointTimes
        guard times.count > 1 else { return entry.currentCheckpointIndex == 0 ? 0 : 1 }
        guard let first = times.first, let last = times.last, last > first else { return 0 }
        let now = entry.date
        if now <= first { return 0 }
        if now >= last  { return 1 }
        for i in 0..<(times.count - 1) {
            let segStart = times[i], segEnd = times[i + 1]
            if now >= segStart && now < segEnd {
                let frac = now.timeIntervalSince(segStart) / segEnd.timeIntervalSince(segStart)
                let base = Double(i) / Double(times.count - 1)
                return min(max(base + frac / Double(times.count - 1), 0), 1)
            }
        }
        return 1
    }

    private var completedCount: Int {
        entry.model.checkpointTimes.filter { $0 <= entry.date }.count
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Row 1: event type + time
            HStack {
                Text(entry.model.eventType.uppercased())
                    .font(.custom("AlbertSans-SemiBold", size: 9))
                    .foregroundColor(widgetSecondary)
                    .tracking(0.5)
                Spacer()
                Text(formatTime(entry.model.eventStartTime))
                    .font(.custom("AlbertSans-SemiBold", size: 10))
                    .foregroundColor(widgetSecondary)
            }
            .padding(.bottom, 4)

            // Row 2: icon + event name + toggle pill
            HStack(spacing: 6) {
                Image(systemName: "graduationcap")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(widgetAccent)
                Text(entry.model.eventName)
                    .font(.custom("AlbertSans-SemiBold", size: 13))
                    .foregroundColor(widgetPrimary)
                    .lineLimit(1)
                Spacer()
                if entry.model.totalCheckpoints > 0 {
                    Capsule()
                        .fill(widgetAccent)
                        .frame(width: 28, height: 16)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .offset(x: 6)
                        )
                }
            }
            .padding(.bottom, 6)

            // Row 3: urgency message — centered, gradient text, light→dark blue top→bottom
            Text(entry.model.urgencyMessage)
                .font(.custom("AlbertSans-Bold", size: 15))
                .foregroundStyle(widgetTextGradient)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 4)

            // Progress bar + labels
            if entry.model.totalCheckpoints > 0 {
                checkpointProgressBar
                    .padding(.bottom, 6)
            }

            // Dismiss pill button
            Button(intent: DismissNudgeIntent()) {
                Text("Dismiss Nudge")
                    .font(.custom("AlbertSans-SemiBold", size: 11))
                    .foregroundColor(widgetAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.85)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .containerBackground(
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.91, blue: 0.95),
                    Color(red: 0.92, green: 0.96, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            for: .widget
        )
    }

    // MARK: - Checkpoint progress bar (gradient fill, dashed interval lines)

    private var checkpointProgressBar: some View {
        let times     = entry.model.checkpointTimes
        let completed = completedCount
        let total     = times.count

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("Checkpoint Progress")
                    .font(.custom("AlbertSans-Regular", size: 9))
                    .foregroundColor(widgetSecondary)
                Spacer()
                Text("\(completed)/\(total)")
                    .font(.custom("AlbertSans-SemiBold", size: 9))
                    .foregroundColor(widgetSecondary)
            }

            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(widgetAccent.opacity(0.18))
                        .frame(height: 8)

                    // Gradient fill
                    widgetBarGradient
                        .frame(width: w * progress, height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Dashed vertical lines at each intermediate checkpoint
                    if total > 1 {
                        ForEach(1..<total, id: \.self) { idx in
                            let x = w * CGFloat(idx) / CGFloat(total)
                            Path { p in
                                p.move(to: CGPoint(x: x, y: 0))
                                p.addLine(to: CGPoint(x: x, y: 8))
                            }
                            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                            .foregroundColor(Color.black.opacity(0.25))
                        }
                    }
                }
            }
            .frame(height: 8)

            // Time labels under each checkpoint position
            if total > 1 {
                HStack(spacing: 0) {
                    ForEach(0..<total, id: \.self) { idx in
                        Text(shortTime(times[idx]))
                            .font(.custom("AlbertSans-Regular", size: 8))
                            .foregroundColor(idx < completed ? widgetAccent : widgetSecondary.opacity(0.7))
                        if idx < total - 1 { Spacer() }
                    }
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }

    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f.string(from: date)
    }
}

// MARK: - Widget Declaration

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

#Preview(as: .systemMedium) {
    NudgeWidgetExtension()
} timeline: {
    SimpleEntry(date: .now, configuration: .init(), model: .idle, currentCheckpointIndex: 0)
}
