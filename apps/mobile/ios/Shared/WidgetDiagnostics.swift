import Foundation
import OSLog

/// The extension writes fixed event names and the resolved App Group identifier.
/// Runner reads the atomic file. The extension queues writes off the provider path.
enum WidgetDiagnostics {
  private static let fileName = "widget-diagnostics.log"
  private static let capacity = 48
  private static let writer = DispatchQueue(label: "com.hofang42.ourney.widgets.diagnostics")
  private static let logger = Logger(subsystem: "com.hofang42.ourney.widgets", category: "provider")

  static func trace<T>(_ operation: String, _ body: () -> T) -> T {
    logger.info("\(operation, privacy: .public) enter")
    let timestamp = Date()
    writer.async {
      let identifier = WidgetAppGroup.current?.identifier ?? "nil"
      logger.info("\(operation, privacy: .public) appGroup=\(identifier, privacy: .public)")
      append(
        "\(operation) enter appGroup=\(identifier)",
        at: timestamp,
        rootDirectory: WidgetSnapshotStore.sharedRootDirectory()
      )
    }
    defer { record("\(operation) exit") }
    return body()
  }

  static func record(_ event: String) {
    // Unified logging can still explain a missing ring file if the extension has no container.
    logger.info("\(event, privacy: .public)")
    let timestamp = Date()
    writer.async {
      append(event, at: timestamp, rootDirectory: WidgetSnapshotStore.sharedRootDirectory())
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
