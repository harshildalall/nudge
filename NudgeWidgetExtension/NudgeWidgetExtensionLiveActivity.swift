//
//  NudgeWidgetExtensionLiveActivity.swift
//  NudgeWidgetExtension
//
//  Created by Dalal on 2/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct NudgeWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct NudgeWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NudgeWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension NudgeWidgetExtensionAttributes {
    fileprivate static var preview: NudgeWidgetExtensionAttributes {
        NudgeWidgetExtensionAttributes(name: "World")
    }
}

extension NudgeWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: NudgeWidgetExtensionAttributes.ContentState {
        NudgeWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: NudgeWidgetExtensionAttributes.ContentState {
         NudgeWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: NudgeWidgetExtensionAttributes.preview) {
   NudgeWidgetExtensionLiveActivity()
} contentStates: {
    NudgeWidgetExtensionAttributes.ContentState.smiley
    NudgeWidgetExtensionAttributes.ContentState.starEyes
}
