import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct LastEventSummaryCalculatorTests {
    @Test
    func returnsNilWhenThereAreNoEvents() {
        #expect(LastEventSummaryCalculator.makeSummary(from: []) == nil)
    }

    @Test
    func returnsMostRecentEventAcrossAllEventTypes() throws {
        let childID = UUID()
        let userID = UUID()
        let feedTime = Date(timeIntervalSince1970: 1_000)
        let nappyTime = Date(timeIntervalSince1970: 2_000)

        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: feedTime,
                        createdAt: feedTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 120,
                    milkType: .formula
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: nappyTime,
                        createdAt: nappyTime,
                        createdBy: userID
                    ),
                    type: .mixed,
                    pooVolume: .heavy
                )
            ),
        ]

        let summary = try #require(LastEventSummaryCalculator.makeSummary(from: events))

        #expect(summary.kind == .nappy)
        #expect(summary.title == "Nappy")
        #expect(summary.detailText == "Mixed • Poo: Heavy")
        #expect(summary.occurredAt == nappyTime)
    }

    @Test
    func formatsSleepEventsInProgressAndCompletedFeeds() throws {
        let childID = UUID()
        let userID = UUID()
        let sleepStart = Date(timeIntervalSince1970: 3_000)
        let sleepEnd = Date(timeIntervalSince1970: 7_800)
        let feedEnd = Date(timeIntervalSince1970: 9_000)

        let completedSleep = try #require(
            LastEventSummaryCalculator.makeSummary(
                from: [
                    .sleep(
                        try SleepEvent(
                            metadata: EventMetadata(
                                childID: childID,
                                occurredAt: sleepEnd,
                                createdAt: sleepEnd,
                                createdBy: userID
                            ),
                            startedAt: sleepStart,
                            endedAt: sleepEnd
                        )
                    ),
                ]
            )
        )
        let activeSleep = try #require(
            LastEventSummaryCalculator.makeSummary(
                from: [
                    .sleep(
                        try SleepEvent(
                            metadata: EventMetadata(
                                childID: childID,
                                occurredAt: sleepStart,
                                createdAt: sleepStart,
                                createdBy: userID
                            ),
                            startedAt: sleepStart
                        )
                    ),
                ]
            )
        )
        let breastFeed = try #require(
            LastEventSummaryCalculator.makeSummary(
                from: [
                    .breastFeed(
                        try BreastFeedEvent(
                            metadata: EventMetadata(
                                childID: childID,
                                occurredAt: feedEnd,
                                createdAt: feedEnd,
                                createdBy: userID
                            ),
                            side: .both,
                            startedAt: feedEnd.addingTimeInterval(-4_500),
                            endedAt: feedEnd
                        )
                    ),
                ]
            )
        )

        #expect(completedSleep.detailText == "1h 20m")
        #expect(activeSleep.detailText == "In progress")
        #expect(breastFeed.detailText == "1h 15m • Both")
    }
}
