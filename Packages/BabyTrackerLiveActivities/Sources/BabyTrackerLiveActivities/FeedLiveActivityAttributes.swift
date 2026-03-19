import ActivityKit
import BabyTrackerDomain
import Foundation

public struct FeedLiveActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public let childName: String
        public let lastFeedKind: BabyEventKind
        public let lastFeedAt: Date

        public init(
            childName: String,
            lastFeedKind: BabyEventKind,
            lastFeedAt: Date
        ) {
            self.childName = childName
            self.lastFeedKind = lastFeedKind
            self.lastFeedAt = lastFeedAt
        }
    }

    public let childID: UUID

    public init(childID: UUID) {
        self.childID = childID
    }
}
