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
}
