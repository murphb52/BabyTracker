import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct BuildTimelineStripDatasetUseCaseTests {
    @Test
    func quarterHourSlotsApplyPriorityAndPadToSevenDays() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let today = calendar.startOfDay(for: now)
        let tenAM = try #require(calendar.date(byAdding: .hour, value: 10, to: today))
        let elevenAM = try #require(calendar.date(byAdding: .hour, value: 11, to: today))

        let childID = UUID()
        let userID = UUID()
        let metadata = EventMetadata(childID: childID, occurredAt: tenAM, createdBy: userID)

        let bottle = try BottleFeedEvent(metadata: metadata, amountMilliliters: 120)
        let sleep = try SleepEvent(metadata: metadata, startedAt: tenAM, endedAt: elevenAM)

        let dataset = BuildTimelineStripDatasetUseCase().execute(
            events: [.bottleFeed(bottle), .sleep(sleep)],
            calendar: calendar,
            now: now
        )

        let todayColumn = try #require(dataset.columns.last)
        let tenAMSlot = (10 * 60) / 15

        #expect(dataset.columns.count >= 7)
        #expect(todayColumn.slots.count == 96)
        #expect(todayColumn.slots[tenAMSlot].kind == .sleep)
    }
}
