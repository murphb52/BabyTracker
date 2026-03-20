import BabyTrackerDomain
import Foundation
import Testing

struct BabyEventDomainTests {
    @Test
    func lastWriteWinsUsesUpdatedAtThenUpdaterThenRecordIdentifier() {
        let childID = UUID()
        let creatorID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let earlierUpdaterID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
        let laterUpdaterID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        let earlierRecordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!
        let laterRecordID = UUID(uuidString: "00000000-0000-0000-0000-0000000000BB")!
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let updatedAt = Date(timeIntervalSince1970: 2_000)

        let newerLocal = EventMetadata(
            id: earlierRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt.addingTimeInterval(10),
            updatedBy: earlierUpdaterID
        )
        let olderRemote = EventMetadata(
            id: laterRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt,
            updatedBy: laterUpdaterID
        )
        let laterUpdaterLocal = EventMetadata(
            id: earlierRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt,
            updatedBy: laterUpdaterID
        )
        let earlierUpdaterRemote = EventMetadata(
            id: laterRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt,
            updatedBy: earlierUpdaterID
        )
        let laterRecordLocal = EventMetadata(
            id: laterRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt,
            updatedBy: laterUpdaterID
        )
        let earlierRecordRemote = EventMetadata(
            id: earlierRecordID,
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID,
            updatedAt: updatedAt,
            updatedBy: laterUpdaterID
        )

        #expect(LastWriteWinsResolver.prefersLocal(newerLocal, over: olderRemote))
        #expect(LastWriteWinsResolver.prefersLocal(laterUpdaterLocal, over: earlierUpdaterRemote))
        #expect(LastWriteWinsResolver.prefersLocal(laterRecordLocal, over: earlierRecordRemote))
    }

    @Test
    func breastFeedsSupportOptionalAndBothSides() throws {
        let childID = UUID()
        let userID = UUID()
        let start = Date(timeIntervalSince1970: 1_000)
        let end = start.addingTimeInterval(900)

        let noSideEvent = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: end,
                createdAt: end,
                createdBy: userID
            ),
            side: nil,
            startedAt: start,
            endedAt: end
        )
        let bothSidesEvent = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: end.addingTimeInterval(60),
                createdAt: end.addingTimeInterval(60),
                createdBy: userID
            ),
            side: .both,
            startedAt: start.addingTimeInterval(60),
            endedAt: end.addingTimeInterval(60)
        )

        #expect(noSideEvent.side == nil)
        #expect(bothSidesEvent.side == .both)
    }

    @Test
    func breastFeedsRequirePositiveDuration() {
        let childID = UUID()
        let userID = UUID()
        let time = Date(timeIntervalSince1970: 2_000)

        #expect(throws: BabyEventError.invalidDateRange) {
            _ = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: time,
                    createdAt: time,
                    createdBy: userID
                ),
                side: .left,
                startedAt: time,
                endedAt: time
            )
        }

        #expect(throws: BabyEventError.invalidDateRange) {
            _ = try BreastFeedEvent(
                metadata: EventMetadata(
                    childID: childID,
                    occurredAt: time,
                    createdAt: time,
                    createdBy: userID
                ),
                side: .right,
                startedAt: time,
                endedAt: time.addingTimeInterval(-60)
            )
        }
    }

    @Test
    func updatingBreastFeedRecomputesStartTime() throws {
        let childID = UUID()
        let userID = UUID()
        let originalEnd = Date(timeIntervalSince1970: 3_000)
        let original = try BreastFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: originalEnd,
                createdAt: originalEnd,
                createdBy: userID
            ),
            side: .left,
            startedAt: originalEnd.addingTimeInterval(-600),
            endedAt: originalEnd
        )
        let updatedEnd = originalEnd.addingTimeInterval(1_800)

        let updated = try original.updating(
            durationMinutes: 20,
            endTime: updatedEnd,
            side: .both,
            updatedBy: userID
        )

        #expect(updated.endedAt == updatedEnd)
        #expect(updated.startedAt == updatedEnd.addingTimeInterval(-1_200))
        #expect(updated.side == .both)
        #expect(updated.metadata.occurredAt == updatedEnd)
    }

    @Test
    func updatingBottleFeedRejectsNonPositiveAmounts() throws {
        let childID = UUID()
        let userID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 4_000)
        let original = try BottleFeedEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: userID
            ),
            amountMilliliters: 120
        )

        #expect(throws: BabyEventError.invalidBottleAmount) {
            _ = try original.updating(
                amountMilliliters: 0,
                occurredAt: occurredAt.addingTimeInterval(60),
                milkType: .formula,
                updatedBy: userID
            )
        }
    }

    @Test
    func updatingNappySupportsValidEditsAndRejectsInvalidPooColor() throws {
        let childID = UUID()
        let userID = UUID()
        let occurredAt = Date(timeIntervalSince1970: 4_500)
        let original = try NappyEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: occurredAt,
                createdAt: occurredAt,
                createdBy: userID
            ),
            type: .poo,
            intensity: .medium,
            pooColor: .brown
        )

        let updated = try original.updating(
            type: .mixed,
            occurredAt: occurredAt.addingTimeInterval(300),
            intensity: .high,
            pooColor: .green,
            updatedBy: userID
        )

        #expect(updated.type == .mixed)
        #expect(updated.intensity == .high)
        #expect(updated.pooColor == .green)
        #expect(updated.metadata.occurredAt == occurredAt.addingTimeInterval(300))

        #expect(throws: NappyEntryError.pooColorRequiresPooOrMixed) {
            _ = try original.updating(
                type: .dry,
                occurredAt: occurredAt.addingTimeInterval(600),
                intensity: .low,
                pooColor: .yellow,
                updatedBy: userID
            )
        }
    }

    @Test
    func updatingSleepSupportsOpenEndedAndCompletedSessions() throws {
        let childID = UUID()
        let userID = UUID()
        let originalStart = Date(timeIntervalSince1970: 4_800)
        let original = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: originalStart,
                createdAt: originalStart,
                createdBy: userID
            ),
            startedAt: originalStart
        )

        let updatedStart = originalStart.addingTimeInterval(600)
        let updatedEnd = updatedStart.addingTimeInterval(1_800)

        let activeUpdate = try original.updating(
            startedAt: updatedStart,
            endedAt: nil,
            updatedBy: userID
        )
        let completedUpdate = try original.updating(
            startedAt: updatedStart,
            endedAt: updatedEnd,
            updatedBy: userID
        )

        #expect(activeUpdate.startedAt == updatedStart)
        #expect(activeUpdate.endedAt == nil)
        #expect(activeUpdate.metadata.occurredAt == updatedStart)
        #expect(completedUpdate.startedAt == updatedStart)
        #expect(completedUpdate.endedAt == updatedEnd)
        #expect(completedUpdate.metadata.occurredAt == updatedEnd)
    }

    @Test
    func updatingSleepRejectsEndBeforeStart() throws {
        let childID = UUID()
        let userID = UUID()
        let originalStart = Date(timeIntervalSince1970: 4_900)
        let original = try SleepEvent(
            metadata: EventMetadata(
                childID: childID,
                occurredAt: originalStart,
                createdAt: originalStart,
                createdBy: userID
            ),
            startedAt: originalStart
        )

        #expect(throws: BabyEventError.invalidDateRange) {
            _ = try original.updating(
                startedAt: originalStart.addingTimeInterval(600),
                endedAt: originalStart.addingTimeInterval(300),
                updatedBy: userID
            )
        }
    }

    @Test
    func restoreDeletedClearsSoftDeleteMetadata() {
        let childID = UUID()
        let creatorID = UUID()
        let updaterID = UUID()
        let createdAt = Date(timeIntervalSince1970: 5_000)
        let deletedAt = createdAt.addingTimeInterval(120)
        let restoredAt = deletedAt.addingTimeInterval(120)
        var metadata = EventMetadata(
            childID: childID,
            occurredAt: createdAt,
            createdAt: createdAt,
            createdBy: creatorID
        )

        metadata.markDeleted(at: deletedAt, by: updaterID)
        metadata.restoreDeleted(at: restoredAt, by: creatorID)

        #expect(metadata.isDeleted == false)
        #expect(metadata.deletedAt == nil)
        #expect(metadata.updatedAt == restoredAt)
        #expect(metadata.updatedBy == creatorID)
    }
}
