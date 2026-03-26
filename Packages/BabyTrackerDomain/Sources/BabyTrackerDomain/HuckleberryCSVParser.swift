import Foundation

/// Parses a CSV export from the Huckleberry app into `ImportableEvent` values.
///
/// CSV column order: Type, Start, End, Duration, Start Condition, Start Location, End Condition, Notes
///
/// Known event types and mappings:
/// - "Sleep"  → SleepImport (Start → startedAt, End → endedAt)
/// - "Feed"   → BottleFeedImport or BreastFeedImport depending on Start Location
/// - "Diaper" → NappyImport (End column may carry poo color, e.g. "brown")
public struct HuckleberryCSVParser {

    private enum Column: Int {
        case type = 0
        case start = 1
        case end = 2
        case duration = 3
        case startCondition = 4
        case startLocation = 5
        case endCondition = 6
        case notes = 7
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public init() {}

    /// Parse raw CSV data, returning successfully-parsed events and a list of skip reasons.
    public func parse(data: Data) -> CSVParseResult {
        guard let raw = String(data: data, encoding: .utf8) else {
            return CSVParseResult(events: [], skippedCount: 1, skippedReasons: ["Could not decode file as UTF-8"])
        }
        return parse(string: raw)
    }

    public func parse(string: String) -> CSVParseResult {
        let lines = string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return CSVParseResult(events: [], skippedCount: 0, skippedReasons: [])
        }

        // Skip header row (first line contains column names)
        let dataLines = lines.dropFirst()

        var events: [ImportableEvent] = []
        var skippedReasons: [String] = []
        var skippedCount = 0

        for (offset, line) in dataLines.enumerated() {
            let rowNumber = offset + 2  // +2 because we dropped first line and rows are 1-indexed
            let columns = parseCSVLine(line)

            guard columns.count >= 7 else {
                skippedReasons.append("Row \(rowNumber): Not enough columns")
                skippedCount += 1
                continue
            }

            let type = columns[Column.type.rawValue]
            let startStr = columns[Column.start.rawValue]
            let endStr = columns[Column.end.rawValue]
            let durationStr = columns[Column.duration.rawValue]
            let startCondition = columns[Column.startCondition.rawValue]
            let startLocation = columns[Column.startLocation.rawValue]
            let endCondition = columns[Column.endCondition.rawValue]
            let notes = columns.count > Column.notes.rawValue ? columns[Column.notes.rawValue] : ""

            guard let startDate = parseDate(startStr) else {
                skippedReasons.append("Row \(rowNumber): Invalid start date '\(startStr)'")
                skippedCount += 1
                continue
            }

            let notesValue = notes.isEmpty ? nil : notes

            do {
                let event: ImportableEvent?
                switch type {
                case "Sleep":
                    event = try parseSleep(
                        start: startDate,
                        endStr: endStr,
                        durationStr: durationStr,
                        notes: notesValue,
                        rowNumber: rowNumber
                    )
                case "Feed":
                    event = try parseFeed(
                        start: startDate,
                        endStr: endStr,
                        durationStr: durationStr,
                        startCondition: startCondition,
                        startLocation: startLocation,
                        endCondition: endCondition,
                        notes: notesValue,
                        rowNumber: rowNumber
                    )
                case "Diaper":
                    event = try parseDiaper(
                        start: startDate,
                        endStr: endStr,
                        endCondition: endCondition,
                        notes: notesValue,
                        rowNumber: rowNumber
                    )
                default:
                    skippedReasons.append("Row \(rowNumber): Unknown type '\(type)'")
                    skippedCount += 1
                    continue
                }

                if let event {
                    events.append(event)
                } else {
                    skippedCount += 1
                }
            } catch let error as ParseError {
                skippedReasons.append("Row \(rowNumber): \(error.message)")
                skippedCount += 1
            } catch {
                skippedReasons.append("Row \(rowNumber): \(error.localizedDescription)")
                skippedCount += 1
            }
        }

        return CSVParseResult(events: events, skippedCount: skippedCount, skippedReasons: skippedReasons)
    }

    // MARK: - Event parsers

    private func parseSleep(
        start: Date,
        endStr: String,
        durationStr: String,
        notes: String?,
        rowNumber: Int
    ) throws -> ImportableEvent? {
        guard let endedAt = resolveEndDate(startDate: start, endStr: endStr, durationStr: durationStr) else {
            throw ParseError("Missing or invalid end time for Sleep event")
        }
        guard endedAt > start else {
            throw ParseError("Sleep end must be after start")
        }
        let metadata = ImportEventMetadata(occurredAt: endedAt, notes: notes)
        return .sleep(SleepImport(metadata: metadata, startedAt: start, endedAt: endedAt))
    }

    private func parseFeed(
        start: Date,
        endStr: String,
        durationStr: String,
        startCondition: String,
        startLocation: String,
        endCondition: String,
        notes: String?,
        rowNumber: Int
    ) throws -> ImportableEvent? {
        switch startLocation {
        case "Bottle":
            return try parseBottleFeed(start: start, startCondition: startCondition, endCondition: endCondition, notes: notes)
        case "Breast":
            return try parseBreastFeed(start: start, endStr: endStr, durationStr: durationStr, startCondition: startCondition, endCondition: endCondition, notes: notes)
        default:
            throw ParseError("Unknown feed location '\(startLocation)'")
        }
    }

    private func parseBottleFeed(
        start: Date,
        startCondition: String,
        endCondition: String,
        notes: String?
    ) throws -> ImportableEvent {
        // End Condition contains amount, e.g. "70ml"
        guard let ml = parseMillilitres(endCondition) else {
            throw ParseError("Could not parse bottle amount from '\(endCondition)'")
        }
        let milkType = parseMilkType(startCondition)
        let metadata = ImportEventMetadata(occurredAt: start, notes: notes)
        return .bottleFeed(BottleFeedImport(metadata: metadata, amountMilliliters: ml, milkType: milkType))
    }

    private func parseBreastFeed(
        start: Date,
        endStr: String,
        durationStr: String,
        startCondition: String,
        endCondition: String,
        notes: String?
    ) throws -> ImportableEvent {
        // startCondition may be "HH:MMR" (right side duration)
        // endCondition may be "HH:MML" (left side duration)
        let rightSeconds = parseSideDuration(startCondition, suffix: "R")
        let leftSeconds = parseSideDuration(endCondition, suffix: "L")

        let side: BreastSide?
        if leftSeconds != nil && rightSeconds != nil {
            side = .both
        } else if rightSeconds != nil {
            side = .right
        } else if leftSeconds != nil {
            side = .left
        } else {
            side = nil
        }

        guard let endedAt = resolveEndDate(startDate: start, endStr: endStr, durationStr: durationStr) else {
            throw ParseError("Missing or invalid end time for Breast Feed event")
        }
        guard endedAt > start else {
            throw ParseError("Breast feed end must be after start")
        }

        let durationMinutes = parseDurationMinutes(durationStr) ?? Int(endedAt.timeIntervalSince(start) / 60)
        let metadata = ImportEventMetadata(occurredAt: endedAt, notes: notes)
        return .breastFeed(BreastFeedImport(
            metadata: metadata,
            startedAt: start,
            endedAt: endedAt,
            durationMinutes: max(1, durationMinutes),
            side: side,
            leftDurationSeconds: leftSeconds,
            rightDurationSeconds: rightSeconds
        ))
    }

    private func parseDiaper(
        start: Date,
        endStr: String,
        endCondition: String,
        notes: String?,
        rowNumber: Int
    ) throws -> ImportableEvent? {
        // The End column sometimes holds a poo color (e.g. "brown") rather than a timestamp.
        // If it doesn't parse as a date, treat it as poo color.
        let pooColor: PooColor?
        if !endStr.isEmpty, parseDate(endStr) == nil {
            pooColor = parsePooColor(endStr)
        } else {
            pooColor = nil
        }

        guard !endCondition.isEmpty else {
            throw ParseError("Missing diaper contents description")
        }

        let (nappyType, peeVolume, pooVolume) = parseDiaperContents(endCondition)
        let metadata = ImportEventMetadata(occurredAt: start, notes: notes)
        return .nappy(NappyImport(
            metadata: metadata,
            type: nappyType,
            peeVolume: peeVolume,
            pooVolume: pooVolume,
            pooColor: pooColor
        ))
    }

    // MARK: - Parsing helpers

    /// Parses a CSV line respecting quoted fields. Fields may be wrapped in double quotes.
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }

    private func parseDate(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        return Self.dateFormatter.date(from: string)
    }

    /// Resolves the end date from either the End column or Start + Duration.
    private func resolveEndDate(startDate: Date, endStr: String, durationStr: String) -> Date? {
        if let end = parseDate(endStr) { return end }
        if let minutes = parseDurationMinutes(durationStr), minutes > 0 {
            return startDate.addingTimeInterval(TimeInterval(minutes * 60))
        }
        return nil
    }

    /// Parses "HH:MM" → total minutes.
    private func parseDurationMinutes(_ string: String) -> Int? {
        guard !string.isEmpty else { return nil }
        let parts = string.components(separatedBy: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else { return nil }
        return hours * 60 + minutes
    }

    /// Parses "HH:MMR" or "HH:MML" → seconds, stripping the suffix letter.
    private func parseSideDuration(_ string: String, suffix: Character) -> Int? {
        guard string.last == suffix else { return nil }
        let timeStr = String(string.dropLast())
        guard let minutes = parseDurationMinutes(timeStr) else { return nil }
        return minutes * 60
    }

    /// Parses "70ml" → 70.
    private func parseMillilitres(_ string: String) -> Int? {
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)
        guard lower.hasSuffix("ml") else { return nil }
        let numberStr = String(lower.dropLast(2)).trimmingCharacters(in: .whitespaces)
        return Int(numberStr)
    }

    private func parseMilkType(_ string: String) -> MilkType? {
        switch string.trimmingCharacters(in: .whitespaces) {
        case "Breast Milk": return .breastMilk
        case "Formula":     return .formula
        case "Mixed":       return .mixed
        default:            return nil
        }
    }

    private func parsePooColor(_ string: String) -> PooColor? {
        switch string.lowercased().trimmingCharacters(in: .whitespaces) {
        case "yellow":  return .yellow
        case "mustard": return .mustard
        case "brown":   return .brown
        case "green":   return .green
        case "black":   return .black
        default:        return .other
        }
    }

    /// Parses diaper contents like "Poo:small", "Pee:large", "Both, pee:small poo:medium".
    /// Returns (nappyType, peeVolume, pooVolume).
    private func parseDiaperContents(_ string: String) -> (NappyType, NappyVolume?, NappyVolume?) {
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)

        // Extract pee and poo volumes from the string
        let peeVolume = extractVolume(from: lower, prefix: "pee:")
        let pooVolume = extractVolume(from: lower, prefix: "poo:")

        let nappyType: NappyType
        if lower.hasPrefix("both") {
            nappyType = .mixed
        } else if lower.hasPrefix("poo") {
            nappyType = .poo
        } else if lower.hasPrefix("pee") {
            nappyType = .wee
        } else {
            // Fallback: infer from what volumes were found
            switch (peeVolume != nil, pooVolume != nil) {
            case (true, true):  nappyType = .mixed
            case (true, false): nappyType = .wee
            case (false, true): nappyType = .poo
            default:            nappyType = .dry
            }
        }

        return (nappyType, peeVolume, pooVolume)
    }

    /// Extracts a NappyVolume following a prefix like "pee:" or "poo:".
    private func extractVolume(from string: String, prefix: String) -> NappyVolume? {
        guard let range = string.range(of: prefix) else { return nil }
        let afterPrefix = String(string[range.upperBound...])
        // Take the next word (up to next space or end)
        let word = afterPrefix.components(separatedBy: .whitespaces).first ?? ""
        return parseVolume(word)
    }

    private func parseVolume(_ string: String) -> NappyVolume? {
        switch string.lowercased().trimmingCharacters(in: .whitespaces) {
        case "small": return .light
        case "medium": return .medium
        case "large": return .heavy
        default: return nil
        }
    }
}

// MARK: - Internal error type

private struct ParseError: Error {
    let message: String
    init(_ message: String) { self.message = message }
}
