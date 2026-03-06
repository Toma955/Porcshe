import WidgetKit
import SwiftUI

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("eBike")
        .description("Speed, battery, range")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .systemSmall])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), speed: 0, batteryPercent: 0, rangeKm: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date(), speed: 0, batteryPercent: 0, rangeKm: 0))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        completion(Timeline(entries: [SimpleEntry(date: Date(), speed: 0, batteryPercent: 0, rangeKm: 0)], policy: .never))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let speed: Double
    let batteryPercent: Int
    let rangeKm: Double
}

struct LockScreenWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(entry.speed, specifier: "%.0f") km/h")
            Text("\(entry.batteryPercent)%")
            Text("\(entry.rangeKm, specifier: "%.0f") km")
        }
    }
}
