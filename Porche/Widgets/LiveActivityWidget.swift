import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EBikeAttributes.self) { context in
            Text("Ride: \(context.state.speed) km/h")
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("Ride") }
                DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.batteryPercent)%") }
            } compactLeading: {
                Text("Ride")
            } compactTrailing: {
                Text("\(context.state.batteryPercent)%")
            } minimal: {
                Text("Ride")
            }
        }
    }
}
