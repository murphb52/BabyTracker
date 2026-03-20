import BabyTrackerDomain
import Foundation

public struct ActiveSleepSessionViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let startedAt: Date

    public init(
        id: UUID,
        startedAt: Date
    ) {
        self.id = id
        self.startedAt = startedAt
    }

    public init(event: SleepEvent) {
        id = event.id
        startedAt = event.startedAt
    }
}
