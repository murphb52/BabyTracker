import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct LastSleepSummaryCalculatorTests {
    @Test
    func returnsNilWhenThereAreNoSleepEvents() {
        #expect(LastSleepSummaryCalculator.makeSummary(from: []) == nil)
    }

    @Test
    func prefersActiveSleepWhenPresent() throws {
        let childID = UUID()
        let userID = UUID()
        let completedEnd = Date(timeIntervalSince1970: 2_000)
        let activeStart = Date(timeIntervalSince1970: 3_000)
        let completedSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: completedEnd,
                createdAt: completedEnd,
                createdBy: userID
            ),
            startedAt: completedEnd.addingTimeInterval(-900),
            endedAt: completedEnd
        )
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: activeStart,
                createdAt: activeStart,
                createdBy: userID
            ),
            startedAt: activeStart
        )

        let summary = try #require(
            LastSleepSummaryCalculator.makeSummary(
                from: [.sleep(completedSleep), .sleep(activeSleep)],
                activeSleep: activeSleep
            )
        )

        #expect(summary.isActive)
        #expect(summary.startedAt == activeStart)
        #expect(summary.endedAt == nil)
    }

    @Test
    func usesLatestCompletedSleepWhenNoActiveSleepExists() throws {
        let childID = UUID()
        let userID = UUID()
        let earlierEnd = Date(timeIntervalSince1970: 1_500)
        let laterEnd = Date(timeIntervalSince1970: 2_500)
        let earlierSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: earlierEnd,
                createdAt: earlierEnd,
                createdBy: userID
            ),
            startedAt: earlierEnd.addingTimeInterval(-600),
            endedAt: earlierEnd
        )
        let laterSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: laterEnd,
                createdAt: laterEnd,
                createdBy: userID
            ),
            startedAt: laterEnd.addingTimeInterval(-1_200),
            endedAt: laterEnd
        )

        let summary = try #require(
            LastSleepSummaryCalculator.makeSummary(
                from: [.sleep(earlierSleep), .sleep(laterSleep)]
            )
        )

        #expect(summary.isActive == false)
        #expect(summary.startedAt == laterSleep.startedAt)
        #expect(summary.endedAt == laterEnd)
    }

    @Test
    func recentSleepRowsExcludeActiveSessionsAndStayNewestFirst() throws {
        let childID = UUID()
        let userID = UUID()
        let earlierEnd = Date(timeIntervalSince1970: 1_500)
        let laterEnd = Date(timeIntervalSince1970: 2_500)
        let activeStart = Date(timeIntervalSince1970: 3_500)
        let earlierSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: earlierEnd,
                createdAt: earlierEnd,
                createdBy: userID
            ),
            startedAt: earlierEnd.addingTimeInterval(-600),
            endedAt: earlierEnd
        )
        let laterSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: laterEnd,
                createdAt: laterEnd,
                createdBy: userID
            ),
            startedAt: laterEnd.addingTimeInterval(-900),
            endedAt: laterEnd
        )
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: activeStart,
                createdAt: activeStart,
                createdBy: userID
            ),
            startedAt: activeStart
        )

        let rows = [
            BabyEvent.sleep(activeSleep),
            BabyEvent.sleep(laterSleep),
            BabyEvent.sleep(earlierSleep),
        ].compactMap(RecentSleepEventViewState.init)

        #expect(rows.count == 2)
        #expect(rows.map(\.id) == [laterSleep.id, earlierSleep.id])
        #expect(rows.first?.detailText.contains("15 min") == true)
        #expect(rows.first?.detailText.contains("-") == true)
    }
}
