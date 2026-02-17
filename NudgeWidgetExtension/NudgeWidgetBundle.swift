import WidgetKit
import SwiftUI

@main
struct NudgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        NudgeWidgetExtension()
        NudgeWidgetExtensionControl()
        if #available(iOS 16.1, *) {
            NudgeLiveActivity()
        }
    }
}

@available(iOS 16.1, *)
struct NudgeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NudgeActivityAttributes.self) { context in
            NudgeLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.eventName)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Starts \(formatted(context.attributes.eventStartTime))")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.urgencyMessage)
                }
            } compactLeading: {
                Image(systemName: "alarm")
            } compactTrailing: {
                Text(context.state.urgencyMessage)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "alarm")
            }
        }
    }

    private func formatted(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}
