import BabyTrackerDomain
import BabyTrackerLiveActivities
import Foundation

extension FeedLiveActivityAttributes {
    static let preview = Self(childID: FeedLiveActivityPreviewData.childID)
}

extension FeedLiveActivityAttributes.ContentState {
    static let previewRecentFeed = Self(
        childID: FeedLiveActivityPreviewData.childID,
        childName: "Robyn Murphy",
        lastFeedKind: .bottleFeed,
        lastFeedAt: Date.now.addingTimeInterval(-35 * 60),
        lastSleepAt: Date.now.addingTimeInterval(-2 * 60 * 60),
        activeSleepStartedAt: nil,
        lastNappyAt: Date.now.addingTimeInterval(-75 * 60)
    )

    static let previewActiveSleep = Self(
        childID: FeedLiveActivityPreviewData.childID,
        childName: "Robyn Murphy",
        lastFeedKind: .breastFeed,
        lastFeedAt: Date.now.addingTimeInterval(-95 * 60),
        lastSleepAt: Date.now.addingTimeInterval(-3 * 60 * 60),
        activeSleepStartedAt: Date.now.addingTimeInterval(-28 * 60),
        lastNappyAt: Date.now.addingTimeInterval(-2 * 60 * 60)
    )

    static let previewMissingMetrics = Self(
        childID: FeedLiveActivityPreviewData.childID,
        childName: "Christopher James Murphy",
        lastFeedKind: .bottleFeed,
        lastFeedAt: Date.now.addingTimeInterval(-12 * 60),
        lastSleepAt: nil,
        activeSleepStartedAt: nil,
        lastNappyAt: nil
    )
}

enum FeedLiveActivityPreviewData {
    static let childID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
}
