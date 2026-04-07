import BabyTrackerDomain
import Foundation

public struct CurrentBreastFeedCardViewState: Equatable, Sendable {
    public let id: UUID
    public let startedAt: Date
    public let side: BreastSide?

    public init(id: UUID, startedAt: Date, side: BreastSide?) {
        self.id = id
        self.startedAt = startedAt
        self.side = side
    }
}
