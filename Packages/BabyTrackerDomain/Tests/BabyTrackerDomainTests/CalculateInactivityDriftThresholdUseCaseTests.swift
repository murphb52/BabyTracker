import XCTest
@testable import BabyTrackerDomain

final class CalculateInactivityDriftThresholdUseCaseTests: XCTestCase {
    func testExecuteReturnsDefaultWhenTooFewEvents() throws {
        let childID = UUID()
        let caregiverID = UUID()

        let events: [BabyEvent] = try [
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 0)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 1)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 2))
        ]

        let threshold = CalculateInactivityDriftThresholdUseCase().execute(.init(events: events))

        XCTAssertEqual(threshold, CalculateInactivityDriftThresholdUseCase.defaultThreshold)
    }

    func testExecuteIgnoresGapsAdjacentToSleepEvents() throws {
        let childID = UUID()
        let caregiverID = UUID()

        let events: [BabyEvent] = try [
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 0)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 1)),
            makeSleepEvent(childID: childID, caregiverID: caregiverID, startedAt: date(hourOffset: 2), durationHours: 8),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 11)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 12)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(hourOffset: 13))
        ]

        let threshold = CalculateInactivityDriftThresholdUseCase().execute(.init(events: events))

        XCTAssertEqual(threshold, 2 * 60 * 60)
    }

    func testExecuteAppliesMinimumThresholdForTightCadence() throws {
        let childID = UUID()
        let caregiverID = UUID()

        let events: [BabyEvent] = try [
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(minuteOffset: 0)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(minuteOffset: 15)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(minuteOffset: 30)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(minuteOffset: 45)),
            makeBottleEvent(childID: childID, caregiverID: caregiverID, occurredAt: date(minuteOffset: 60))
        ]

        let threshold = CalculateInactivityDriftThresholdUseCase().execute(.init(events: events))

        XCTAssertEqual(threshold, CalculateInactivityDriftThresholdUseCase.minimumThreshold)
    }

    private func makeBottleEvent(childID: UUID, caregiverID: UUID, occurredAt: Date) throws -> BabyEvent {
        .bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: caregiverID
            ),
            amountMilliliters: 120
        ))
    }

    private func makeSleepEvent(
        childID: UUID,
        caregiverID: UUID,
        startedAt: Date,
        durationHours: Double
    ) throws -> BabyEvent {
        let endedAt = startedAt.addingTimeInterval(durationHours * 60 * 60)
        return .sleep(try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: endedAt,
                createdAt: endedAt,
                createdBy: caregiverID
            ),
            startedAt: startedAt,
            endedAt: endedAt
        ))
    }

    private func date(hourOffset: Int = 0, minuteOffset: Int = 0) -> Date {
        Date(timeIntervalSince1970: TimeInterval((hourOffset * 60 + minuteOffset) * 60))
    }
}
