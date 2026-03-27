import XCTest
@testable import BabyTrackerDomain

final class BuildRemoteCaregiverNotificationUseCaseTests: XCTestCase {
    func testSingleSleepStartBuildsSpecificMessage() throws {
        let caregiver = try UserIdentity(displayName: "Alex")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let sleep = try SleepEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 100),
                createdAt: Date(timeIntervalSince1970: 100),
                createdBy: caregiver.id,
                updatedAt: Date(timeIntervalSince1970: 100),
                updatedBy: caregiver.id
            ),
            startedAt: Date(timeIntervalSince1970: 100)
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "10:00 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .sleep(sleep)),
        ]))

        XCTAssertEqual(content?.body, "Alex started a sleep timer.")
    }

    func testSingleNappyBuildsWetMessage() throws {
        let caregiver = try UserIdentity(displayName: "Sam")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let nappy = try NappyEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 100),
                createdBy: caregiver.id,
                updatedBy: caregiver.id
            ),
            type: .wee
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "11:45 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy)),
        ]))

        XCTAssertEqual(content?.body, "Sam logged a wet nappy at 11:45 AM.")
    }

    func testManyChangesFromMultipleCaregiversBuildsAggregateMessage() throws {
        let caregiverOne = try UserIdentity(displayName: "Sam")
        let caregiverTwo = try UserIdentity(displayName: "Alex")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiverOne.id)
        let feed = try BottleFeedEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: caregiverOne.id, updatedBy: caregiverOne.id),
            amountMilliliters: 120,
            milkType: .formula
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase()
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiverOne.displayName, event: .bottleFeed(feed)),
            .init(actorDisplayName: caregiverTwo.displayName, event: .bottleFeed(feed)),
        ]))

        XCTAssertEqual(content?.body, "2 new updates from caregivers.")
    }
}
