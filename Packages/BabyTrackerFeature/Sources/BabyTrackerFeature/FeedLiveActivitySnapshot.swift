import BabyTrackerDomain
import Foundation

public struct FeedLiveActivitySnapshot: Equatable, Sendable {
    public let childID: UUID
    public let childName: String
    public let lastFeedKind: BabyEventKind
    public let lastFeedAt: Date

    public init(
        childID: UUID,
        childName: String,
        lastFeedKind: BabyEventKind,
        lastFeedAt: Date
    ) {
        self.childID = childID
        self.childName = childName
        self.lastFeedKind = lastFeedKind
        self.lastFeedAt = lastFeedAt
    }
}
