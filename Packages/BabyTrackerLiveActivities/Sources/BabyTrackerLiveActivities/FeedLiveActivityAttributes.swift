import ActivityKit
import BabyTrackerDomain
import Foundation

public struct FeedLiveActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
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

    public let childID: UUID

    /// When the activity was requested. iOS stops applying updates ~8 hours
    /// after `Activity.request`, so the app uses this to restart the activity
    /// in time. Optional so activities started by older builds still decode.
    public let startedAt: Date?

    public init(childID: UUID, startedAt: Date? = nil) {
        self.childID = childID
        self.startedAt = startedAt
    }
}
