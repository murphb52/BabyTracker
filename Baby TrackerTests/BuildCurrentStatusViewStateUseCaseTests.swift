import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct BuildCurrentStatusViewStateUseCaseTests {
    private let childID = UUID()
    private let userID = UUID()

    private func makeChild() throws -> Child {
        try Child(id: childID, name: "Poppy", birthDate: Date(timeIntervalSince1970: 0), createdBy: userID, preferredFeedVolumeUnit: .milliliters)
    }

    @Test
    func returnsNilsWhenNoEvents() throws {
        let child = try makeChild()
        let result = BuildCurrentStatusViewStateUseCase.execute(events: [], child: child)

        #expect(result.lastBreastFeed == nil)
        #expect(result.lastBottleFeed == nil)
        #expect(result.lastNappy == nil)
        #expect(result.lastSleep == nil)
        #expect(result.feedsTodayCount == 0)
    }

    @Test
    func populatesLastBreastFeedWithDetailText() throws {
        let child = try makeChild()
        let t = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    side: .left,
                    startedAt: t.addingTimeInterval(-600),
                    endedAt: t
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(events: events, child: child)

        let breastFeed = try #require(result.lastBreastFeed)
        #expect(breastFeed.kind == .breastFeed)
        #expect(breastFeed.occurredAt == t)
        #expect(breastFeed.detailText?.contains("Left") == true)
        #expect(result.lastBottleFeed == nil)
    }

    @Test
    func populatesLastBottleFeedWithDetailText() throws {
        let child = try makeChild()
        let t = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    amountMilliliters: 150,
                    milkType: .formula
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(events: events, child: child)

        let bottleFeed = try #require(result.lastBottleFeed)
        #expect(bottleFeed.kind == .bottleFeed)
        #expect(bottleFeed.occurredAt == t)
        #expect(bottleFeed.detailText?.contains("Formula") == true)
        #expect(result.lastBreastFeed == nil)
    }

    @Test
    func picksMostRecentBreastFeed() throws {
        let child = try makeChild()
        let earlier = Date(timeIntervalSince1970: 5_000)
        let later = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: earlier, createdAt: earlier, createdBy: userID),
                    side: .right,
                    startedAt: earlier.addingTimeInterval(-300),
                    endedAt: earlier
                )
            ),
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: later, createdAt: later, createdBy: userID),
                    side: .left,
                    startedAt: later.addingTimeInterval(-900),
                    endedAt: later
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(events: events, child: child)

        #expect(result.lastBreastFeed?.occurredAt == later)
        #expect(result.lastBreastFeed?.detailText?.contains("Left") == true)
    }

    @Test
    func populatesLastNappyWithDetailText() throws {
        let child = try makeChild()
        let t = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .nappy(
                try NappyEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    type: .poo,
                    pooVolume: .medium,
                    pooColor: .yellow
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(events: events, child: child)

        let nappy = try #require(result.lastNappy)
        #expect(nappy.occurredAt == t)
        #expect(nappy.detailText?.contains("Poo") == true)
    }

    @Test
    func countsFeedsTodayAcrossBothTypes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let child = try makeChild()
        let day = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 12)))
        let morning = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 8)))
        let midday = try #require(calendar.date(from: DateComponents(year: 2026, month: 4, day: 1, hour: 11)))
        let yesterday = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31, hour: 20)))

        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: morning, createdAt: morning, createdBy: userID),
                    side: .left,
                    startedAt: morning.addingTimeInterval(-600),
                    endedAt: morning
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: midday, createdAt: midday, createdBy: userID),
                    amountMilliliters: 120
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: yesterday, createdAt: yesterday, createdBy: userID),
                    amountMilliliters: 100
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(events: events, child: child, day: day, calendar: calendar)

        #expect(result.feedsTodayCount == 2)
    }
}
