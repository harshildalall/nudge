//
//  AppIntent.swift
//  NudgeWidgetExtension
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Nudge checkpoint widget." }
}

/// Fired when the user taps "Dismiss Nudge" on the home screen widget.
/// Writes a dismiss flag to the shared App Group so the main app ends the session on next tick.
struct DismissNudgeIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss Nudge"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        NudgeWidgetSharedStore.requestDismiss()
        NudgeWidgetSharedStore.clear()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Fired when the user taps "+ Buffer" on the home screen widget.
/// Writes a buffer flag to the shared App Group so the main app adds 15 min on next tick.
struct AddBufferIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Buffer Time"
    static var isDiscoverable: Bool = false

    func perform() async throws -> some IntentResult {
        NudgeWidgetSharedStore.requestBuffer()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
