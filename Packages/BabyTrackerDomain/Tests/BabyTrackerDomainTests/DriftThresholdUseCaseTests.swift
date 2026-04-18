import BabyTrackerDomain
import Foundation
import Testing

struct DriftThresholdUseCaseTests {
    private let childID = UUID()
    private let userID = UUID()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let calendar = Calendar(identifier: .gregorian)

    @Test
    func inactivityThresholdUsesFixedTwelveHoursWithoutHistory() {
        let useCase = CalculateInactivityDriftThresholdUseCase()

        let threshold = useCase.execute(.init(events: []))

        #expect(threshold == 12 * 60 * 60)
    }

    @Test
    func inactivityThresholdUsesSixHoursForDaytimeEvents() throws {
        let useCase = CalculateInactivityDriftThresholdUseCase()
        let events = try [
            bottleFeed(atHour: 9),
            bottleFeed(atHour: 11),
            bottleFeed(atHour: 14),
        ]

        let threshold = useCase.execute(.init(events: events))

        #expect(threshold == 6 * 60 * 60)
    }

    @Test
    func inactivityThresholdUsesTwelveHoursForNighttimeEvents() throws {
        let useCase = CalculateInactivityDriftThresholdUseCase()
        let events = try [
            bottleFeed(atHour: 1),
            bottleFeed(atHour: 3),
            bottleFeed(atHour: 18),
        ]

        let threshold = useCase.execute(.init(events: events))

        #expect(threshold == 12 * 60 * 60)
    }

    @Test
    func sleepThresholdUsesFixedTwelveHoursWithoutHistory() {
        let useCase = CalculateSleepDriftThresholdUseCase()
        let startedAt = dateAtHour(1)

        let threshold = useCase.execute(.init(activeSleepStartedAt: startedAt))

        #expect(threshold == 12 * 60 * 60)
    }

    @Test
    func sleepThresholdUsesSixHoursForDaytimeSleepStarts() throws {
        let useCase = CalculateSleepDriftThresholdUseCase()
        let startedAt = dateAtHour(14)

        let threshold = useCase.execute(.init(activeSleepStartedAt: startedAt))

        #expect(threshold == 6 * 60 * 60)
    }

    @Test
    func sleepThresholdUsesTwelveHoursForNighttimeSleepStarts() {
        let useCase = CalculateSleepDriftThresholdUseCase()
        let startedAt = dateAtHour(18)

        let threshold = useCase.execute(.init(activeSleepStartedAt: startedAt))

        #expect(threshold == 12 * 60 * 60)
    }

    @Test
    func sleepThresholdUsesSixHoursAtFiveAmBoundary() {
        let useCase = CalculateSleepDriftThresholdUseCase()
        let startedAt = dateAtHour(5)

        let threshold = useCase.execute(.init(activeSleepStartedAt: startedAt))

        #expect(threshold == 6 * 60 * 60)
    }

    @Test
    func inactivityThresholdUsesTwelveHoursAtSixPmBoundary() throws {
        let useCase = CalculateInactivityDriftThresholdUseCase()
        let events = try [bottleFeed(atHour: 18)]

        let threshold = useCase.execute(.init(events: events))

        #expect(threshold == 12 * 60 * 60)
    }

    private func bottleFeed(atHour hour: Int) throws -> BabyEvent {
        let occurredAt = dateAtHour(hour)
        let event = try BottleFeedEvent(
            metadata: EventMetadata(childID: childID, occurredAt: occurredAt, createdBy: userID),
            amountMilliliters: 120
        )
        return .bottleFeed(event)
    }

    private func dateAtHour(_ hour: Int) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: now
        )!
    }

}
