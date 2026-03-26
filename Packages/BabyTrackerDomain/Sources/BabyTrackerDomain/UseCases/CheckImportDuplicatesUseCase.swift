import Foundation

/// Checks a list of parsed import events against the child's existing timeline,
/// tagging each as `.new` or `.duplicate`.
///
/// Two events are considered duplicates when they share the same event kind and
/// their `occurredAt` timestamps truncate to the same minute — matching the
/// minute-only precision of the Huckleberry CSV format.
@MainActor
public struct CheckImportDuplicatesUseCase: UseCase {
    public struct Input {
        public let events: [ImportableEvent]
        public let childID: UUID

        public init(events: [ImportableEvent], childID: UUID) {
            self.events = events
            self.childID = childID
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> [TaggedImportEvent] {
        let existing = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)
        let existingKeys = Set(existing.map { DuplicateKey(kind: $0.kind, date: $0.metadata.occurredAt) })

        return input.events.map { event in
            let key = DuplicateKey(kind: event.kind, date: event.occurredAt)
            let status: ImportDuplicateStatus = existingKeys.contains(key) ? .duplicate : .new
            return TaggedImportEvent(event: event, duplicateStatus: status)
        }
    }
}

// MARK: - Duplicate key

/// Identifies an event by kind + minute-truncated timestamp.
private struct DuplicateKey: Hashable {
    let kind: BabyEventKind
    /// Seconds-since-reference-date floored to the nearest minute.
    let minuteTimestamp: Int

    init(kind: BabyEventKind, date: Date) {
        self.kind = kind
        self.minuteTimestamp = Int(date.timeIntervalSinceReferenceDate) / 60
    }
}
