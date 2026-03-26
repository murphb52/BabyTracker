import Foundation

/// Parses a Nest JSON export file into a ``CSVParseResult`` containing ``ImportableEvent`` values.
///
/// Reuses `CSVParseResult` as the common parse-result type shared by both Huckleberry CSV and Nest JSON imports.
public struct NestJSONParser {
    public init() {}

    public func parse(data: Data) -> CSVParseResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: NestExportData
        do {
            exportData = try decoder.decode(NestExportData.self, from: data)
        } catch {
            return CSVParseResult(events: [], skippedCount: 0, skippedReasons: [])
        }

        var events: [ImportableEvent] = []
        var skippedReasons: [String] = []

        for nestEvent in exportData.events {
            if let event = importableEvent(from: nestEvent, skippedReasons: &skippedReasons) {
                events.append(event)
            }
        }

        return CSVParseResult(events: events, skippedCount: skippedReasons.count, skippedReasons: skippedReasons)
    }

    // MARK: - Mapping

    private func importableEvent(from nestEvent: NestEventExport, skippedReasons: inout [String]) -> ImportableEvent? {
        switch nestEvent {
        case .breastFeed(let e):
            let durationMinutes = Int(e.endedAt.timeIntervalSince(e.startedAt) / 60)
            let metadata = ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes)
            return .breastFeed(BreastFeedImport(
                metadata: metadata,
                startedAt: e.startedAt,
                endedAt: e.endedAt,
                durationMinutes: durationMinutes,
                side: e.side,
                leftDurationSeconds: e.leftDurationSeconds,
                rightDurationSeconds: e.rightDurationSeconds
            ))

        case .bottleFeed(let e):
            guard e.amountMilliliters > 0 else {
                skippedReasons.append("Bottle feed at \(e.occurredAt.formatted()): amount must be greater than zero")
                return nil
            }
            let metadata = ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes)
            return .bottleFeed(BottleFeedImport(
                metadata: metadata,
                amountMilliliters: e.amountMilliliters,
                milkType: e.milkType
            ))

        case .sleep(let e):
            guard e.endedAt >= e.startedAt else {
                skippedReasons.append("Sleep at \(e.occurredAt.formatted()): end time is before start time")
                return nil
            }
            let metadata = ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes)
            return .sleep(SleepImport(
                metadata: metadata,
                startedAt: e.startedAt,
                endedAt: e.endedAt
            ))

        case .nappy(let e):
            let metadata = ImportEventMetadata(occurredAt: e.occurredAt, notes: e.notes.isEmpty ? nil : e.notes)
            return .nappy(NappyImport(
                metadata: metadata,
                type: e.nappyType,
                peeVolume: e.peeVolume,
                pooVolume: e.pooVolume,
                pooColor: e.pooColor
            ))
        }
    }
}
