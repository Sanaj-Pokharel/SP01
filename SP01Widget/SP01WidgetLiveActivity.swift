//
//  SP01WidgetLiveActivity.swift
//  SP01Widget
//
//  Created by Sanaj Pokharel on 31/1/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SP01WidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct SP01WidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SP01WidgetAttributes.self) { context in
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

extension SP01WidgetAttributes {
    fileprivate static var preview: SP01WidgetAttributes {
        SP01WidgetAttributes(name: "World")
    }
}

extension SP01WidgetAttributes.ContentState {
    fileprivate static var smiley: SP01WidgetAttributes.ContentState {
        SP01WidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: SP01WidgetAttributes.ContentState {
         SP01WidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: SP01WidgetAttributes.preview) {
   SP01WidgetLiveActivity()
} contentStates: {
    SP01WidgetAttributes.ContentState.smiley
    SP01WidgetAttributes.ContentState.starEyes
}
