import XCTest
@testable import BabyTrackerDomain

final class CalculateSleepDriftThresholdUseCaseTests: XCTestCase {
    func testExecuteReturnsDefaultThresholdWhenFewerThanThreeValidSleeps() throws {
        let childID = UUID()
        let caregiverID = UUID()
        let nightStart = date(year: 2026, month: 4, day: 10, hour: 21)

        let sleeps = [
            try makeSleep(childID: childID, caregiverID: caregiverID, startedAt: nightStart, durationHours: 2.0),
            try makeSleep(childID: childID, caregiverID: caregiverID, startedAt: nightStart.addingTimeInterval(-86_400), durationHours: 1.8)
        ]

        let threshold = CalculateSleepDriftThresholdUseCase().execute(
            .init(completedSleepEvents: sleeps, activeSleepStartedAt: nightStart)
        )

        XCTAssertEqual(threshold, CalculateSleepDriftThresholdUseCase.defaultThreshold)
    }

    func testExecuteUsesNightContextWhenEnoughMatchingSessionsExist() throws {
        let childID = UUID()
        let caregiverID = UUID()
        let activeNightStart = date(year: 2026, month: 4, day: 20, hour: 21)

        let nighttimeSleeps: [SleepEvent] = try [
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeNightStart.addingTimeInterval(-86_400), durationHours: 7.5),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeNightStart.addingTimeInterval(-2 * 86_400), durationHours: 8.0),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeNightStart.addingTimeInterval(-3 * 86_400), durationHours: 7.8)
        ]

        let daytimeNaps: [SleepEvent] = try [
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: date(year: 2026, month: 4, day: 19, hour: 11), durationHours: 0.8),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: date(year: 2026, month: 4, day: 18, hour: 13), durationHours: 0.7),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: date(year: 2026, month: 4, day: 17, hour: 10), durationHours: 0.9)
        ]

        let threshold = CalculateSleepDriftThresholdUseCase().execute(
            .init(completedSleepEvents: nighttimeSleeps + daytimeNaps, activeSleepStartedAt: activeNightStart)
        )

        XCTAssertGreaterThan(threshold, 8 * 60 * 60)
    }

    func testExecuteAppliesMinimumThresholdForShortSessions() throws {
        let childID = UUID()
        let caregiverID = UUID()
        let activeDayStart = date(year: 2026, month: 4, day: 20, hour: 12)

        let naps: [SleepEvent] = try [
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeDayStart.addingTimeInterval(-86_400), durationHours: 0.5),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeDayStart.addingTimeInterval(-2 * 86_400), durationHours: 0.6),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeDayStart.addingTimeInterval(-3 * 86_400), durationHours: 0.7),
            makeSleep(childID: childID, caregiverID: caregiverID, startedAt: activeDayStart.addingTimeInterval(-4 * 86_400), durationHours: 0.8)
        ]

        let threshold = CalculateSleepDriftThresholdUseCase().execute(
            .init(completedSleepEvents: naps, activeSleepStartedAt: activeDayStart)
        )

        XCTAssertEqual(threshold, CalculateSleepDriftThresholdUseCase.minimumThreshold)
    }

    private func makeSleep(
        childID: UUID,
        caregiverID: UUID,
        startedAt: Date,
        durationHours: Double
    ) throws -> SleepEvent {
        let endedAt = startedAt.addingTimeInterval(durationHours * 60 * 60)
        return try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: endedAt,
                createdAt: endedAt,
                createdBy: caregiverID
            ),
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int) -> Date {
        let components = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        )
        return components.date!
    }
}
