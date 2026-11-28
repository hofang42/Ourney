import Foundation
import OSLog

/// The extension writes fixed event names and the resolved App Group identifier.
/// Runner reads the atomic file. Events are saved before the extension returns.
enum WidgetDiagnostics {
  private static let fileName = "widget-diagnostics.log"
  private static let capacity = 48
  private static let writer = DispatchQueue(label: "com.hofang42.ourney.widgets.diagnostics")
  private static let logger = Logger(subsystem: "com.hofang42.ourney.widgets", category: "provider")

  static func record(_ event: String, rootDirectory: URL?) {
    // Unified logging can still explain a missing ring file if the extension has no container.
    logger.notice("\(event, privacy: .public)")
    guard let rootDirectory else { return }
    let timestamp = Date()
    writer.sync {
      append(event, at: timestamp, rootDirectory: rootDirectory)
    }
  }

  static func append(_ event: String, at timestamp: Date = Date(), rootDirectory: URL?) {
    guard let rootDirectory else { return }
    let url = rootDirectory.appendingPathComponent(fileName)
    let message = event.split(whereSeparator: \.isNewline).joined(separator: " ").prefix(200)
    let line = "\(timestamp.ISO8601Format()) \(message)"

    do {
      if !FileManager.default.fileExists(atPath: rootDirectory.path) {
        try WidgetSnapshotStore.ensureDirectoryPrepared(rootDirectory)
      }
      let previous = lines(in: url).suffix(capacity - 1)
      let contents = (Array(previous) + [line]).joined(separator: "\n") + "\n"
      try Data(contents.utf8).write(
        to: url,
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
    } catch {
      logger.error("widget diagnostics write failed")
    }
  }

  static func recentLines(rootDirectory: URL? = WidgetSnapshotStore.sharedRootDirectory()) -> [String] {
    guard let rootDirectory else { return [] }
    return Array(lines(in: rootDirectory.appendingPathComponent(fileName)).suffix(20))
  }

  private static func lines(in url: URL) -> [String] {
    guard let file = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    return file.split(separator: "\n").map(String.init)
  }
}
