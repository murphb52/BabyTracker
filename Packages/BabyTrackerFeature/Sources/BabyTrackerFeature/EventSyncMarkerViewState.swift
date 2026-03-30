import BabyTrackerDomain
import Foundation

public struct EventSyncMarkerViewState: Equatable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let occurredAt: Date
    public let updatedAt: Date

    public init(event: BabyEvent) {
        self.id = event.id
        self.kind = event.kind
        self.occurredAt = event.metadata.occurredAt
        self.updatedAt = event.metadata.updatedAt
    }
}
