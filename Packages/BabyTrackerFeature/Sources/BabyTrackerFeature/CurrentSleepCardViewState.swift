import Foundation

public struct CurrentSleepCardViewState: Equatable, Sendable {
    public let sleepEventID: UUID
    public let startedAt: Date

    public init(
        sleepEventID: UUID,
        startedAt: Date
    ) {
        self.sleepEventID = sleepEventID
        self.startedAt = startedAt
    }
}
