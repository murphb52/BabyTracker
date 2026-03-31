import BabyTrackerDomain
import Foundation

enum SummaryScreenPreviewFactory {
    static var summaryState: SummaryScreenState {
        SummaryScreenState(
            events: sampleEvents,
            emptyStateTitle: "No summary data yet",
            emptyStateMessage: "Log feeds, sleep, and nappies to unlock trends."
        )
    }

    private static var sampleEvents: [BabyEvent] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let childID = UUID()
        let userID = UUID()
        let now = Date()
        let today = calendar.startOfDay(for: now)

        let todayFeed = calendar.date(byAdding: .hour, value: 8, to: today) ?? now
        let todayBottle = calendar.date(byAdding: .hour, value: 11, to: today) ?? now
        let todayNappy = calendar.date(byAdding: .hour, value: 13, to: today) ?? now
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? now
        let yesterdaySleepEnd = calendar.date(byAdding: .hour, value: 6, to: yesterday) ?? now
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today) ?? now
        let twoDaysAgoNappy = calendar.date(byAdding: .hour, value: 17, to: twoDaysAgo) ?? now

        return [
            .breastFeed(
                try! BreastFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: todayFeed,
                        createdAt: todayFeed,
                        createdBy: userID
                    ),
                    side: .left,
                    startedAt: todayFeed.addingTimeInterval(-1_200),
                    endedAt: todayFeed
                )
            ),
            .bottleFeed(
                try! BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: todayBottle,
                        createdAt: todayBottle,
                        createdBy: userID
                    ),
                    amountMilliliters: 150,
                    milkType: .formula
                )
            ),
            .nappy(
                try! NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: todayNappy,
                        createdAt: todayNappy,
                        createdBy: userID
                    ),
                    type: .mixed,
                    pooVolume: .medium,
                    pooColor: .yellow
                )
            ),
            .sleep(
                try! SleepEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: yesterdaySleepEnd,
                        createdAt: yesterdaySleepEnd,
                        createdBy: userID
                    ),
                    startedAt: yesterdaySleepEnd.addingTimeInterval(-7_200),
                    endedAt: yesterdaySleepEnd
                )
            ),
            .nappy(
                try! NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: twoDaysAgoNappy,
                        createdAt: twoDaysAgoNappy,
                        createdBy: userID
                    ),
                    type: .wee,
                    peeVolume: .light
                )
            ),
        ]
    }
}
