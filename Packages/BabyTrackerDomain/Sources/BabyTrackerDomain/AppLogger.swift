import Foundation
import Observation

public enum LogLevel: String, Sendable, CaseIterable, Codable {
    case debug
    case info
    case warning
    case error
}

public struct LogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String

    public init(id: UUID = UUID(), timestamp: Date = .now, level: LogLevel, category: String, message: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }
}

@MainActor
@Observable
public final class AppLogger {
    public static let shared = AppLogger()
    public private(set) var entries: [LogEntry] = []

    private static let maxEntries = 2000

    private init() {}

    public func log(_ level: LogLevel, category: String, _ message: String) {
        entries.append(LogEntry(level: level, category: category, message: message))
        if entries.count > Self.maxEntries {
            entries.removeFirst()
        }
    }

    public func clear() {
        entries.removeAll()
    }
}
