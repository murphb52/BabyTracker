import CloudKit
import Foundation

enum CloudKitRecordNames {
    static func zoneID(
        for childID: UUID,
        ownerName: String = CKCurrentUserDefaultName
    ) -> CKRecordZone.ID {
        CKRecordZone.ID(
            zoneName: "child-\(childID.uuidString)",
            ownerName: ownerName
        )
    }

    static func childRecordID(
        childID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "child.\(childID.uuidString)",
            zoneID: zoneID
        )
    }

    static func shareRecordID(
        childID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "share.child.\(childID.uuidString)",
            zoneID: zoneID
        )
    }

    static func userRecordID(
        userID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "user.\(userID.uuidString)",
            zoneID: zoneID
        )
    }

    static func membershipRecordID(
        membershipID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "membership.\(membershipID.uuidString)",
            zoneID: zoneID
        )
    }

    static func breastFeedRecordID(
        eventID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "breastFeed.\(eventID.uuidString)",
            zoneID: zoneID
        )
    }

    static func bottleFeedRecordID(
        eventID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "bottleFeed.\(eventID.uuidString)",
            zoneID: zoneID
        )
    }

    static func sleepRecordID(
        eventID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "sleep.\(eventID.uuidString)",
            zoneID: zoneID
        )
    }

    static func nappyRecordID(
        eventID: UUID,
        zoneID: CKRecordZone.ID
    ) -> CKRecord.ID {
        CKRecord.ID(
            recordName: "nappy.\(eventID.uuidString)",
            zoneID: zoneID
        )
    }
}
