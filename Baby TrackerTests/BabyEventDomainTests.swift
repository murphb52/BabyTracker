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
}
