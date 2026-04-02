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
            .init(actorDisplayName: caregiver.displayName, event: .sleep(sleep), isDeleted: false),
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
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: false),
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
            .init(actorDisplayName: caregiverOne.displayName, event: .bottleFeed(feed), isDeleted: false),
            .init(actorDisplayName: caregiverTwo.displayName, event: .bottleFeed(feed), isDeleted: false),
        ]))

        XCTAssertEqual(content?.body, "Caregivers made 2 updates.")
    }

    func testSingleDeletedSleepBuildsDeletedMessage() throws {
        let caregiver = try UserIdentity(displayName: "Alex")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let sleep = try SleepEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 100),
                createdAt: Date(timeIntervalSince1970: 100),
                createdBy: caregiver.id,
                updatedAt: Date(timeIntervalSince1970: 100),
                updatedBy: caregiver.id,
                isDeleted: true
            ),
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200)
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "10:00 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .sleep(sleep), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Alex deleted a sleep log.")
    }

    func testSingleDeletedNappyBuildsDeletedMessage() throws {
        let caregiver = try UserIdentity(displayName: "Sam")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let nappy = try NappyEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 100),
                createdBy: caregiver.id,
                updatedBy: caregiver.id,
                isDeleted: true
            ),
            type: .poo
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "11:00 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Sam deleted a dirty nappy log.")
    }

    func testSingleDeletedBottleFeedBuildsDeletedMessage() throws {
        let caregiver = try UserIdentity(displayName: "Jordan")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let feed = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 100),
                createdBy: caregiver.id,
                updatedBy: caregiver.id,
                isDeleted: true
            ),
            amountMilliliters: 100,
            milkType: .breastMilk
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "9:00 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .bottleFeed(feed), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Jordan deleted a bottle feed log.")
    }

    func testSingleDeletedBreastFeedBuildsDeletedMessage() throws {
        let caregiver = try UserIdentity(displayName: "Morgan")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let feed = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: child.id,
                occurredAt: Date(timeIntervalSince1970: 200),
                createdBy: caregiver.id,
                updatedBy: caregiver.id,
                isDeleted: true
            ),
            side: nil,
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200)
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase(formatTime: { _ in "8:00 AM" })
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .breastFeed(feed), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Morgan deleted a breast feed log.")
    }

    func testMultipleDeletesFromSameCaregiverBuildsDeletedSummary() throws {
        let caregiver = try UserIdentity(displayName: "Alex")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let nappy = try NappyEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: caregiver.id, updatedBy: caregiver.id),
            type: .wee
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase()
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: true),
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: true),
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Alex deleted 3 events.")
    }

    func testMixedAddAndDeleteFromSameCaregiverBuildsMadeUpdatesMessage() throws {
        let caregiver = try UserIdentity(displayName: "Sam")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiver.id)
        let nappy = try NappyEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: caregiver.id, updatedBy: caregiver.id),
            type: .dry
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase()
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: false),
            .init(actorDisplayName: caregiver.displayName, event: .nappy(nappy), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Sam made 2 updates.")
    }

    func testMixedDeletesFromMultipleCaregiversBuildsCaregiversMadeUpdatesMessage() throws {
        let caregiverOne = try UserIdentity(displayName: "Sam")
        let caregiverTwo = try UserIdentity(displayName: "Alex")
        let child = try Child(name: "Robin", birthDate: nil, createdBy: caregiverOne.id)
        let nappy = try NappyEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: caregiverOne.id, updatedBy: caregiverOne.id),
            type: .dry
        )

        let useCase = BuildRemoteCaregiverNotificationUseCase()
        let content = useCase.execute(.init(changes: [
            .init(actorDisplayName: caregiverOne.displayName, event: .nappy(nappy), isDeleted: true),
            .init(actorDisplayName: caregiverTwo.displayName, event: .nappy(nappy), isDeleted: true),
        ]))

        XCTAssertEqual(content?.body, "Caregivers made 2 updates.")
    }
}
