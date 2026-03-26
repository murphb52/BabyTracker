import Foundation

public struct CSVImportResult: Equatable, Sendable {
    public let importedCount: Int
    public let skippedParseCount: Int
    public let skippedSaveCount: Int
    public let skippedReasons: [String]

    public var totalSkipped: Int { skippedParseCount + skippedSaveCount }

    public init(
        importedCount: Int,
        skippedParseCount: Int,
        skippedSaveCount: Int,
        skippedReasons: [String]
    ) {
        self.importedCount = importedCount
        self.skippedParseCount = skippedParseCount
        self.skippedSaveCount = skippedSaveCount
        self.skippedReasons = skippedReasons
    }
}

public struct CSVParseResult: Equatable, Sendable {
    public let events: [ImportableEvent]
    public let skippedCount: Int
    public let skippedReasons: [String]

    public var bottleFeedCount: Int { events.filter { if case .bottleFeed = $0 { true } else { false } }.count }
    public var breastFeedCount: Int { events.filter { if case .breastFeed = $0 { true } else { false } }.count }
    public var sleepCount: Int { events.filter { if case .sleep = $0 { true } else { false } }.count }
    public var nappyCount: Int { events.filter { if case .nappy = $0 { true } else { false } }.count }

    public var dateRange: ClosedRange<Date>? {
        guard let first = events.map(\.occurredAt).min(),
              let last = events.map(\.occurredAt).max() else { return nil }
        return first...last
    }

    public init(events: [ImportableEvent], skippedCount: Int, skippedReasons: [String]) {
        self.events = events
        self.skippedCount = skippedCount
        self.skippedReasons = skippedReasons
    }
}
