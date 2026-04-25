import BabyTrackerDomain
import CloudKit
import Foundation

public enum CloudKitRecordMapper {
    static func mutableFieldKeys(for recordType: CKRecord.RecordType) -> [CKRecord.FieldKey] {
        switch recordType {
        case CloudKitConfiguration.childRecordType:
            ["name", "birthDate", "createdAt", "createdBy", "isArchived", "preferredFeedVolumeUnit", "imageAsset", "customBottleAmounts"]
        case CloudKitConfiguration.userRecordType:
            ["displayName", "createdAt", "cloudKitUserRecordName"]
        case CloudKitConfiguration.membershipRecordType:
            ["childID", "userID", "role", "status", "invitedAt", "acceptedAt"]
        case CloudKitConfiguration.breastFeedRecordType:
            metadataFieldKeys + ["side", "startedAt", "endedAt", "leftDurationSeconds", "rightDurationSeconds"]
        case CloudKitConfiguration.bottleFeedRecordType:
            metadataFieldKeys + ["amountMilliliters", "milkType"]
        case CloudKitConfiguration.sleepRecordType:
            metadataFieldKeys + ["startedAt", "endedAt"]
        case CloudKitConfiguration.nappyRecordType:
            metadataFieldKeys + ["type", "peeVolume", "pooVolume", "pooColor"]
        default:
            []
        }
    }

    public static func childRecord(
        from child: Child,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.childRecordType,
            recordID: CloudKitRecordNames.childRecordID(
                childID: child.id,
                zoneID: zoneID
            )
        )
        record["name"] = child.name
        record["birthDate"] = child.birthDate
        record["createdAt"] = child.createdAt
        record["updatedAt"] = child.updatedAt
        record["createdBy"] = child.createdBy.uuidString
        record["isArchived"] = child.isArchived
        record["preferredFeedVolumeUnit"] = child.preferredFeedVolumeUnit.rawValue
        if let amounts = child.customBottleAmountsMilliliters,
           let data = try? JSONEncoder().encode(amounts),
           let json = String(data: data, encoding: .utf8) {
            record["customBottleAmounts"] = json
        } else {
            record["customBottleAmounts"] = nil
        }
        if let imageData = child.imageData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("child-image-\(child.id.uuidString).jpg")
            try? imageData.write(to: tempURL)
            record["imageAsset"] = CKAsset(fileURL: tempURL)
        } else {
            record["imageAsset"] = nil
        }
        return record
    }

    static func membershipRecord(
        from membership: Membership,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.membershipRecordType,
            recordID: CloudKitRecordNames.membershipRecordID(
                membershipID: membership.id,
                zoneID: zoneID
            )
        )
        record["childID"] = membership.childID.uuidString
        record["userID"] = membership.userID.uuidString
        record["role"] = membership.role.rawValue
        record["status"] = membership.status.rawValue
        record["invitedAt"] = membership.invitedAt
        record["acceptedAt"] = membership.acceptedAt
        return record
    }

    static func userRecord(
        from user: UserIdentity,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.userRecordType,
            recordID: CloudKitRecordNames.userRecordID(
                userID: user.id,
                zoneID: zoneID
            )
        )
        record["displayName"] = user.displayName
        record["createdAt"] = user.createdAt
        record["cloudKitUserRecordName"] = user.cloudKitUserRecordName
        return record
    }

    public static func eventRecord(
        from event: BabyEvent,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        switch event {
        case let .breastFeed(value):
            return breastFeedRecord(from: value, zoneID: zoneID)
        case let .bottleFeed(value):
            return bottleFeedRecord(from: value, zoneID: zoneID)
        case let .sleep(value):
            return sleepRecord(from: value, zoneID: zoneID)
        case let .nappy(value):
            return nappyRecord(from: value, zoneID: zoneID)
        }
    }

    public static func child(from record: CKRecord) throws -> Child {
        var imageData: Data?
        if let asset = record["imageAsset"] as? CKAsset,
           let url = asset.fileURL {
            imageData = try? Data(contentsOf: url)
        }
        return try Child(
            id: extractUUID(prefix: "child.", from: record.recordID.recordName),
            name: record["name"] as? String ?? "",
            birthDate: record["birthDate"] as? Date,
            createdAt: record["createdAt"] as? Date ?? .now,
            updatedAt: record["updatedAt"] as? Date ?? (record["createdAt"] as? Date ?? .now),
            createdBy: UUID(uuidString: record["createdBy"] as? String ?? "") ?? UUID(),
            isArchived: record["isArchived"] as? Bool ?? false,
            imageData: imageData,
            preferredFeedVolumeUnit: FeedVolumeUnit(rawValue: record["preferredFeedVolumeUnit"] as? String ?? "") ?? .milliliters,
            customBottleAmountsMilliliters: decodeCustomBottleAmounts(record["customBottleAmounts"] as? String)
        )
    }

    private static func decodeCustomBottleAmounts(_ json: String?) -> [Int]? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([Int].self, from: data)
    }

    static func membership(from record: CKRecord) -> Membership {
        Membership(
            id: extractUUID(prefix: "membership.", from: record.recordID.recordName),
            childID: UUID(uuidString: record["childID"] as? String ?? "") ?? UUID(),
            userID: UUID(uuidString: record["userID"] as? String ?? "") ?? UUID(),
            role: MembershipRole(rawValue: record["role"] as? String ?? "") ?? .caregiver,
            status: MembershipStatus(rawValue: record["status"] as? String ?? "") ?? .invited,
            invitedAt: record["invitedAt"] as? Date ?? .now,
            acceptedAt: record["acceptedAt"] as? Date
        )
    }

    static func user(from record: CKRecord) throws -> UserIdentity {
        try UserIdentity(
            id: extractUUID(prefix: "user.", from: record.recordID.recordName),
            displayName: record["displayName"] as? String ?? "",
            createdAt: record["createdAt"] as? Date ?? .now,
            cloudKitUserRecordName: record["cloudKitUserRecordName"] as? String
        )
    }

    public static func event(from record: CKRecord) throws -> BabyEvent {
        switch record.recordType {
        case CloudKitConfiguration.breastFeedRecordType:
            return .breastFeed(try breastFeed(from: record))
        case CloudKitConfiguration.bottleFeedRecordType:
            return .bottleFeed(try bottleFeed(from: record))
        case CloudKitConfiguration.sleepRecordType:
            return .sleep(try sleep(from: record))
        case CloudKitConfiguration.nappyRecordType:
            return .nappy(try nappy(from: record))
        default:
            throw BabyEventError.invalidDateRange
        }
    }

    static func shareTitle(for child: Child) -> String {
        child.name
    }

    private static func breastFeedRecord(
        from event: BreastFeedEvent,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.breastFeedRecordType,
            recordID: CloudKitRecordNames.breastFeedRecordID(
                eventID: event.id,
                zoneID: zoneID
            )
        )
        applyMetadata(event.metadata, to: record)
        if let side = event.side {
            record["side"] = side.rawValue
        }
        record["startedAt"] = event.startedAt
        record["endedAt"] = event.endedAt
        record["leftDurationSeconds"] = event.leftDurationSeconds
        record["rightDurationSeconds"] = event.rightDurationSeconds
        return record
    }

    private static func bottleFeedRecord(
        from event: BottleFeedEvent,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.bottleFeedRecordType,
            recordID: CloudKitRecordNames.bottleFeedRecordID(
                eventID: event.id,
                zoneID: zoneID
            )
        )
        applyMetadata(event.metadata, to: record)
        record["amountMilliliters"] = event.amountMilliliters
        record["milkType"] = event.milkType?.rawValue
        return record
    }

    private static func sleepRecord(
        from event: SleepEvent,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.sleepRecordType,
            recordID: CloudKitRecordNames.sleepRecordID(
                eventID: event.id,
                zoneID: zoneID
            )
        )
        applyMetadata(event.metadata, to: record)
        record["startedAt"] = event.startedAt
        record["endedAt"] = event.endedAt
        return record
    }

    private static func nappyRecord(
        from event: NappyEvent,
        zoneID: CKRecordZone.ID
    ) -> CKRecord {
        let record = CKRecord(
            recordType: CloudKitConfiguration.nappyRecordType,
            recordID: CloudKitRecordNames.nappyRecordID(
                eventID: event.id,
                zoneID: zoneID
            )
        )
        applyMetadata(event.metadata, to: record)
        record["type"] = event.type.rawValue
        record["peeVolume"] = event.peeVolume?.rawValue
        record["pooVolume"] = event.pooVolume?.rawValue
        record["pooColor"] = event.pooColor?.rawValue
        return record
    }

    private static func breastFeed(from record: CKRecord) throws -> BreastFeedEvent {
        try BreastFeedEvent(
            metadata: metadata(from: record, prefix: "breastFeed."),
            side: (record["side"] as? String).flatMap(BreastSide.init(rawValue:)),
            startedAt: record["startedAt"] as? Date ?? .now,
            endedAt: record["endedAt"] as? Date ?? .now,
            leftDurationSeconds: record["leftDurationSeconds"] as? Int,
            rightDurationSeconds: record["rightDurationSeconds"] as? Int
        )
    }

    private static func bottleFeed(from record: CKRecord) throws -> BottleFeedEvent {
        try BottleFeedEvent(
            metadata: metadata(from: record, prefix: "bottleFeed."),
            amountMilliliters: record["amountMilliliters"] as? Int ?? 0,
            milkType: (record["milkType"] as? String).flatMap(MilkType.init(rawValue:))
        )
    }

    private static func sleep(from record: CKRecord) throws -> SleepEvent {
        try SleepEvent(
            metadata: metadata(from: record, prefix: "sleep."),
            startedAt: record["startedAt"] as? Date ?? .now,
            endedAt: record["endedAt"] as? Date
        )
    }

    private static func nappy(from record: CKRecord) throws -> NappyEvent {
        try NappyEvent(
            metadata: metadata(from: record, prefix: "nappy."),
            type: NappyType(rawValue: record["type"] as? String ?? "") ?? .dry,
            peeVolume: (record["peeVolume"] as? String).flatMap(NappyVolume.init(rawValue:)),
            pooVolume: (record["pooVolume"] as? String).flatMap(NappyVolume.init(rawValue:)),
            pooColor: (record["pooColor"] as? String).flatMap(PooColor.init(rawValue:))
        )
    }

    private static func applyMetadata(
        _ metadata: EventMetadata,
        to record: CKRecord
    ) {
        record["childID"] = metadata.childID.uuidString
        record["occurredAt"] = metadata.occurredAt
        record["createdAt"] = metadata.createdAt
        record["createdBy"] = metadata.createdBy.uuidString
        record["updatedAt"] = metadata.updatedAt
        record["updatedBy"] = metadata.updatedBy.uuidString
        record["notes"] = metadata.notes
        record["isDeleted"] = metadata.isDeleted
        record["deletedAt"] = metadata.deletedAt
    }

    private static func metadata(
        from record: CKRecord,
        prefix: String
    ) -> EventMetadata {
        EventMetadata(
            id: extractUUID(prefix: prefix, from: record.recordID.recordName),
            childID: UUID(uuidString: record["childID"] as? String ?? "") ?? UUID(),
            occurredAt: record["occurredAt"] as? Date ?? .now,
            createdAt: record["createdAt"] as? Date ?? .now,
            createdBy: UUID(uuidString: record["createdBy"] as? String ?? "") ?? UUID(),
            updatedAt: record["updatedAt"] as? Date,
            updatedBy: UUID(uuidString: record["updatedBy"] as? String ?? ""),
            notes: record["notes"] as? String ?? "",
            isDeleted: record["isDeleted"] as? Bool ?? false,
            deletedAt: record["deletedAt"] as? Date
        )
    }

    private static func extractUUID(
        prefix: String,
        from recordName: String
    ) -> UUID {
        let rawValue = recordName.replacingOccurrences(of: prefix, with: "")
        return UUID(uuidString: rawValue) ?? UUID()
    }

    private static let metadataFieldKeys: [CKRecord.FieldKey] = [
        "childID",
        "occurredAt",
        "createdAt",
        "createdBy",
        "updatedAt",
        "updatedBy",
        "notes",
        "isDeleted",
        "deletedAt",
    ]
}
