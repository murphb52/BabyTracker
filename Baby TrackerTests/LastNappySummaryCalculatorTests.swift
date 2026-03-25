import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct LastNappySummaryCalculatorTests {
    @Test
    func returnsNilWhenThereAreNoNappies() throws {
        let childID = UUID()
        let userID = UUID()
        let feedTime = Date(timeIntervalSince1970: 1_000)
        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: feedTime,
                        createdAt: feedTime,
                        createdBy: userID
                    ),
                    amountMilliliters: 120
                )
            ),
        ]

        #expect(LastNappySummaryCalculator.makeSummary(from: events) == nil)
    }

    @Test
    func returnsMostRecentNappyWithFormattedDetailText() throws {
        let childID = UUID()
        let userID = UUID()
        let earlierTime = Date(timeIntervalSince1970: 2_000)
        let laterTime = Date(timeIntervalSince1970: 3_000)

        let events: [BabyEvent] = [
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: earlierTime,
                        createdAt: earlierTime,
                        createdBy: userID
                    ),
                    type: .wee,
                    peeVolume: .light
                )
            ),
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(
                        childID: childID,
                        occurredAt: laterTime,
                        createdAt: laterTime,
                        createdBy: userID
                    ),
                    type: .mixed,
                    pooVolume: .heavy,
                    pooColor: .green
                )
            ),
        ]

        let summary = try #require(LastNappySummaryCalculator.makeSummary(from: events))

        #expect(summary.title == "Nappy")
        #expect(summary.detailText == "Mixed • Poo: Heavy • Green")
        #expect(summary.occurredAt == laterTime)
    }
}
