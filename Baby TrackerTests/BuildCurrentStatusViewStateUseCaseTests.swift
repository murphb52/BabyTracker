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
    func returnsEmptyRowsWhenNoEvents() throws {
        let child = try makeChild()
        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: [],
            child: child,
            enabledEventKinds: Set(BabyEventKind.allCases)
        )

        #expect(result.rows.isEmpty)
        #expect(result.lastSleep == nil)
        #expect(result.visibleEventKinds == BabyEventKind.allCases)
    }

    @Test
    func enabledBathProducesBathRow() throws {
        let child = try makeChild()
        let t = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .bath(
                try BathEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    usedShampoo: true,
                    usedSoap: false
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: events,
            child: child,
            enabledEventKinds: [.bath]
        )

        let bath = try #require(result.row(for: .bath))
        #expect(bath.title == "Last bath")
        #expect(bath.elapsedSinceDate == t)
        #expect(bath.detailText == "Shampoo")
    }

    @Test
    func hiddenEventKindsAreOmittedEvenWhenEventsExist() throws {
        let child = try makeChild()
        let t = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .bath(
                try BathEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: t, createdAt: t, createdBy: userID),
                    usedShampoo: true,
                    usedSoap: true
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: events,
            child: child,
            enabledEventKinds: [.bottleFeed]
        )

        #expect(result.row(for: .bath) == nil)
        #expect(result.visibleEventKinds == [.bottleFeed])
    }

    @Test
    func breastFeedAndBottleFeedProduceIndependentRows() throws {
        let child = try makeChild()
        let breastTime = Date(timeIntervalSince1970: 10_000)
        let bottleTime = Date(timeIntervalSince1970: 12_000)
        let events: [BabyEvent] = [
            .breastFeed(
                try BreastFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: breastTime, createdAt: breastTime, createdBy: userID),
                    side: .left,
                    startedAt: breastTime.addingTimeInterval(-600),
                    endedAt: breastTime
                )
            ),
            .bottleFeed(
                try BottleFeedEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: bottleTime, createdAt: bottleTime, createdBy: userID),
                    amountMilliliters: 150,
                    milkType: .formula
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: events,
            child: child,
            enabledEventKinds: [.breastFeed, .bottleFeed]
        )

        #expect(result.row(for: .breastFeed)?.elapsedSinceDate == breastTime)
        #expect(result.row(for: .breastFeed)?.detailText?.contains("Left") == true)
        #expect(result.row(for: .bottleFeed)?.elapsedSinceDate == bottleTime)
        #expect(result.row(for: .bottleFeed)?.detailText?.contains("Formula") == true)
    }

    @Test
    func activeSleepSuppressesCompletedSleepRow() throws {
        let child = try makeChild()
        let startedAt = Date(timeIntervalSince1970: 10_000)
        let activeSleep = try SleepEvent(
            metadata: EventMetadata(childID: childID, occurredAt: startedAt, createdAt: startedAt, createdBy: userID),
            startedAt: startedAt,
            endedAt: nil
        )

        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: [],
            child: child,
            enabledEventKinds: [.sleep],
            activeSleep: activeSleep
        )

        #expect(result.row(for: .sleep) == nil)
        #expect(result.lastSleep?.isActive == true)
        #expect(result.lastSleep?.startedAt == startedAt)
    }

    @Test
    func completedSleepStillAppearsWithoutActiveSleep() throws {
        let child = try makeChild()
        let startedAt = Date(timeIntervalSince1970: 8_000)
        let endedAt = Date(timeIntervalSince1970: 10_000)
        let events: [BabyEvent] = [
            .sleep(
                try SleepEvent(
                    metadata: EventMetadata(childID: childID, occurredAt: startedAt, createdAt: startedAt, createdBy: userID),
                    startedAt: startedAt,
                    endedAt: endedAt
                )
            ),
        ]

        let result = BuildCurrentStatusViewStateUseCase.execute(
            events: events,
            child: child,
            enabledEventKinds: [.sleep]
        )

        let sleep = try #require(result.row(for: .sleep))
        #expect(sleep.elapsedSinceDate == endedAt)
        #expect(sleep.detailText == "33 min")
        #expect(result.lastSleep?.isActive == false)
    }
}
