import BabyTrackerDomain
import Foundation

public struct ActiveSleepSessionViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let startedAt: Date

    public init(event: SleepEvent) {
        id = event.id
        startedAt = event.startedAt
    }
}
