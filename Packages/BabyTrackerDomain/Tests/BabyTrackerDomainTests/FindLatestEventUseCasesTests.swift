import BabyTrackerDomain
import Foundation
import Testing

struct FindLatestEventUseCasesTests {
    @Test
    func latestEventReturnsMostRecentAcrossAllKinds() throws {
        let childID = UUID()
        let userID = UUID()
        let earlier = Date(timeIntervalSince1970: 1_000)
        let later = Date(timeIntervalSince1970: 2_000)

        let bottle = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: earlier,
                createdAt: earlier,
                createdBy: userID
            ),
            amountMilliliters: 120
        )

        let nappy = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: later,
                createdAt: later,
                createdBy: userID
            ),
            type: .mixed
        )

        let result = FindLatestEventUseCases.latestEvent(from: [.bottleFeed(bottle), .nappy(nappy)])

        #expect(result?.metadata.occurredAt == later)
    }

    @Test
    func latestNappySkipsNonNappyEvents() throws {
        let childID = UUID()
        let userID = UUID()
        let feedTime = Date(timeIntervalSince1970: 1_000)
        let nappyTime = Date(timeIntervalSince1970: 2_000)

        let feed = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: feedTime,
                createdAt: feedTime,
                createdBy: userID
            ),
            amountMilliliters: 100
        )

        let nappy = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: nappyTime,
                createdAt: nappyTime,
                createdBy: userID
            ),
            type: .wee
        )

        let result = FindLatestEventUseCases.latestNappy(from: [.bottleFeed(feed), .nappy(nappy)])

        #expect(result?.metadata.occurredAt == nappyTime)
    }

    @Test
    func latestSleepSummaryPrefersActiveSleepWhenProvided() throws {
        let childID = UUID()
        let userID = UUID()
        let completedEnd = Date(timeIntervalSince1970: 1_000)
        let activeStart = Date(timeIntervalSince1970: 2_000)

        let completed = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: completedEnd,
                createdAt: completedEnd,
                createdBy: userID
            ),
            startedAt: completedEnd.addingTimeInterval(-600),
            endedAt: completedEnd
        )

        let active = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: activeStart,
                createdAt: activeStart,
                createdBy: userID
            ),
            startedAt: activeStart
        )

        let summary = FindLatestEventUseCases.latestSleepSummary(
            from: [.sleep(completed), .sleep(active)],
            activeSleep: active
        )

        #expect(summary?.isActive == true)
        #expect(summary?.startedAt == activeStart)
        #expect(summary?.endedAt == nil)
    }
}
