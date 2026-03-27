import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct EventFilterTests {
    private let childID = UUID()
    private let userID = UUID()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func metadata() -> EventMetadata {
        EventMetadata(childID: childID, occurredAt: now, createdBy: userID)
    }

    // MARK: - Empty filter

    @Test
    func emptyFilterMatchesAllEventTypes() throws {
        let bottle = try BottleFeedEvent(metadata: metadata(), amountMilliliters: 120)
        let breast = try BreastFeedEvent(metadata: metadata(), side: nil, startedAt: now, endedAt: now.addingTimeInterval(600))
        let sleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(3600))
        let nappy = try NappyEvent(metadata: metadata(), type: .wee)

        let filter = EventFilter.empty
        #expect(filter.matches(.bottleFeed(bottle)))
        #expect(filter.matches(.breastFeed(breast)))
        #expect(filter.matches(.sleep(sleep)))
        #expect(filter.matches(.nappy(nappy)))
    }

    // MARK: - Event type filter

    @Test
    func eventTypeFilterIncludesMatchingKind() throws {
        let sleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(3600))
        let filter = EventFilter(
            eventTypes: [.sleep],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: nil
        )
        #expect(filter.matches(.sleep(sleep)))
    }

    @Test
    func eventTypeFilterExcludesNonMatchingKind() throws {
        let bottle = try BottleFeedEvent(metadata: metadata(), amountMilliliters: 120)
        let filter = EventFilter(
            eventTypes: [.sleep],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: nil
        )
        #expect(!filter.matches(.bottleFeed(bottle)))
    }

    // MARK: - Nappy type filter

    @Test
    func nappyTypeFilterMatchesByType() throws {
        let poo = try NappyEvent(metadata: metadata(), type: .poo)
        let wee = try NappyEvent(metadata: metadata(), type: .wee)
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [.poo],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: nil
        )
        #expect(filter.matches(.nappy(poo)))
        #expect(!filter.matches(.nappy(wee)))
    }

    // MARK: - Milk type filter

    @Test
    func milkTypeFilterMatchesByType() throws {
        let formula = try BottleFeedEvent(metadata: metadata(), amountMilliliters: 120, milkType: .formula)
        let breastMilk = try BottleFeedEvent(metadata: metadata(), amountMilliliters: 100, milkType: .breastMilk)
        let noType = try BottleFeedEvent(metadata: metadata(), amountMilliliters: 80)
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [.formula],
            breastSides: [],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: nil
        )
        #expect(filter.matches(.bottleFeed(formula)))
        #expect(!filter.matches(.bottleFeed(breastMilk)))
        #expect(!filter.matches(.bottleFeed(noType)))
    }

    // MARK: - Breast side filter

    @Test
    func breastSideFilterMatchesBySide() throws {
        let left = try BreastFeedEvent(metadata: metadata(), side: .left, startedAt: now, endedAt: now.addingTimeInterval(600))
        let right = try BreastFeedEvent(metadata: metadata(), side: .right, startedAt: now, endedAt: now.addingTimeInterval(600))
        let noSide = try BreastFeedEvent(metadata: metadata(), side: nil, startedAt: now, endedAt: now.addingTimeInterval(600))
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [.left],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: nil
        )
        #expect(filter.matches(.breastFeed(left)))
        #expect(!filter.matches(.breastFeed(right)))
        #expect(!filter.matches(.breastFeed(noSide)))
    }

    // MARK: - Sleep duration filter

    @Test
    func sleepMinDurationFilterExcludesShortSleeps() throws {
        let shortSleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(900))  // 15 min
        let longSleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(3600)) // 60 min
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: 30,
            sleepMaxDurationMinutes: nil
        )
        #expect(!filter.matches(.sleep(shortSleep)))
        #expect(filter.matches(.sleep(longSleep)))
    }

    @Test
    func sleepMaxDurationFilterExcludesLongSleeps() throws {
        let shortSleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(900))   // 15 min
        let longSleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: now.addingTimeInterval(7200))  // 120 min
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: nil,
            sleepMaxDurationMinutes: 60
        )
        #expect(filter.matches(.sleep(shortSleep)))
        #expect(!filter.matches(.sleep(longSleep)))
    }

    @Test
    func ongoingSleepPassesDurationFilter() throws {
        let ongoingSleep = try SleepEvent(metadata: metadata(), startedAt: now, endedAt: nil)
        let filter = EventFilter(
            eventTypes: [],
            nappyTypes: [],
            milkTypes: [],
            breastSides: [],
            sleepMinDurationMinutes: 60,
            sleepMaxDurationMinutes: 60
        )
        #expect(filter.matches(.sleep(ongoingSleep)))
    }
}
