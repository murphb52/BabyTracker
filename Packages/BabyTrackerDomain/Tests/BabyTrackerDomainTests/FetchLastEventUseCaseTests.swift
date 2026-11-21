import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct FetchLastEventUseCaseTests {
    private typealias Fixture = AssistantQueryFixtures

    @Test
    func returnsMostRecentEventInCategory() throws {
        let latestFeed = try Fixture.bottle(150, at: Fixture.date(daysAgo: 0, hour: 12))
        let result = try fetchLast(.feeds, events: [
            Fixture.bottle(100, at: Fixture.date(daysAgo: 0, hour: 8)),
            latestFeed,
            Fixture.nappy(.wee, at: Fixture.date(daysAgo: 0, hour: 13)),
        ])

        #expect(result == latestFeed)
    }

    @Test
    func skipsDeletedEvents() throws {
        let keptFeed = try Fixture.bottle(100, at: Fixture.date(daysAgo: 0, hour: 8))
        let result = try fetchLast(.feeds, events: [
            keptFeed,
            Fixture.bottle(150, at: Fixture.date(daysAgo: 0, hour: 12), isDeleted: true),
        ])

        #expect(result == keptFeed)
    }

    @Test
    func returnsNilWhenNothingLogged() throws {
        #expect(try fetchLast(.bath, events: []) == nil)
    }

    private func fetchLast(_ category: EventSummaryCategory, events: [BabyEvent]) throws -> BabyEvent? {
        try FetchLastEventUseCase(eventRepository: AssistantStubEventRepository(events: events))
            .execute(.init(childID: Fixture.childID, category: category))
    }
}
