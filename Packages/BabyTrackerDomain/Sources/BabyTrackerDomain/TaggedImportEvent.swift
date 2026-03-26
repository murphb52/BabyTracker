import Foundation

public enum ImportDuplicateStatus: Equatable, Sendable {
    case new
    case duplicate
}

/// An `ImportableEvent` tagged with whether it already exists in the child's timeline.
public struct TaggedImportEvent: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let event: ImportableEvent
    public let duplicateStatus: ImportDuplicateStatus

    public init(event: ImportableEvent, duplicateStatus: ImportDuplicateStatus) {
        self.id = event.id
        self.event = event
        self.duplicateStatus = duplicateStatus
    }

    public var isDuplicate: Bool { duplicateStatus == .duplicate }
}
