import Foundation
import OSLog
import SwiftUI
import WidgetKit

struct HelloWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "OurneyHelloWidget", provider: HelloTimelineProvider()) { entry in
      let label = Text(verbatim: "hello \(entry.date)")
      if #available(iOSApplicationExtension 17.0, iOS 17.0, *) {
        label.containerBackground(.background, for: .widget)
      } else {
        label
      }
    }
    .configurationDisplayName("Ourney Hello")
    .supportedFamilies([.systemSmall])
  }
}

private struct HelloEntry: TimelineEntry {
  let date: Date
}

private struct HelloTimelineProvider: TimelineProvider {
  // Keep this probe independent of the shared App Group diagnostics file.
  private static let logger = Logger(subsystem: "com.hofang42.ourney.widgets", category: "hello")

  func placeholder(in context: Context) -> HelloEntry {
    Self.logger.notice("hello placeholder enter")
    return HelloEntry(date: Date())
  }

  func getSnapshot(in context: Context, completion: @escaping (HelloEntry) -> Void) {
    Self.logger.notice("hello snapshot enter")
    completion(HelloEntry(date: Date()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HelloEntry>) -> Void) {
    Self.logger.notice("hello timeline enter")
    completion(Timeline(entries: [HelloEntry(date: Date())], policy: .never))
  }
}
