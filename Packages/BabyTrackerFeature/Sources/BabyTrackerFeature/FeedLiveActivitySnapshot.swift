import BabyTrackerDomain
import Foundation

/// The complete desired state of the lock-screen Live Activity for one child.
/// Built by `SyncFeedLiveActivityUseCase` and consumed by the
/// `FeedLiveActivityManaging` implementation, which mirrors it into
/// ActivityKit content.
public struct FeedLiveActivitySnapshot: Codable, Equatable, Sendable {
    public let childID: UUID
    public let childName: String
    public let lastFeedKind: BabyEventKind
    public let lastFeedAt: Date
    public let lastSleepAt: Date?
    public let activeSleepStartedAt: Date?
    public let lastNappyAt: Date?

    public init(
        childID: UUID,
        childName: String,
        lastFeedKind: BabyEventKind,
        lastFeedAt: Date,
        lastSleepAt: Date?,
        activeSleepStartedAt: Date?,
        lastNappyAt: Date?
    ) {
        self.childID = childID
        self.childName = childName
        self.lastFeedKind = lastFeedKind
        self.lastFeedAt = lastFeedAt
        self.lastSleepAt = lastSleepAt
        self.activeSleepStartedAt = activeSleepStartedAt
        self.lastNappyAt = lastNappyAt
    }
}
