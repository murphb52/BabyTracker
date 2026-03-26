import BabyTrackerDomain
import Foundation

/// Presentation state for the import preview phase.
/// Holds the tagged events and the user's current selection.
public struct ImportPreviewState: Equatable, Sendable {
    public let parseResult: CSVParseResult
    public let taggedEvents: [TaggedImportEvent]
    /// IDs of events the user has chosen to include in the import.
    public var selectedEventIDs: Set<UUID>

    public init(parseResult: CSVParseResult, taggedEvents: [TaggedImportEvent]) {
        self.parseResult = parseResult
        self.taggedEvents = taggedEvents
        // Default: select all new events, deselect duplicates
        self.selectedEventIDs = Set(taggedEvents.filter { !$0.isDuplicate }.map(\.id))
    }

    // MARK: - Derived

    public var newEvents: [TaggedImportEvent] {
        taggedEvents.filter { !$0.isDuplicate }
    }

    public var duplicateEvents: [TaggedImportEvent] {
        taggedEvents.filter(\.isDuplicate)
    }

    public var selectedCount: Int { selectedEventIDs.count }

    public var selectedEvents: [ImportableEvent] {
        taggedEvents
            .filter { selectedEventIDs.contains($0.id) }
            .map(\.event)
    }

    // MARK: - Mutations

    public mutating func toggle(_ id: UUID) {
        if selectedEventIDs.contains(id) {
            selectedEventIDs.remove(id)
        } else {
            selectedEventIDs.insert(id)
        }
    }

    public mutating func skipAllDuplicates() {
        for event in duplicateEvents {
            selectedEventIDs.remove(event.id)
        }
    }

    public mutating func selectAllEvents() {
        selectedEventIDs = Set(taggedEvents.map(\.id))
    }
}
