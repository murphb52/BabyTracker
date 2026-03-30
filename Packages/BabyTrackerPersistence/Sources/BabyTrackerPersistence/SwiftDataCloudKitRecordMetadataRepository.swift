import CloudKit
import Foundation
import SwiftData

@MainActor
public final class SwiftDataCloudKitRecordMetadataRepository: CloudKitRecordMetadataRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public func loadSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws -> Data? {
        try fetchMetadata(
            for: recordID,
            databaseScope: databaseScope
        )?.systemFieldsData
    }

    public func saveSystemFields(
        _ systemFieldsData: Data,
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws {
        let storageKey = Self.storageKey(
            for: recordID,
            databaseScope: databaseScope
        )
        let existingMetadata = try fetchMetadata(
            for: recordID,
            databaseScope: databaseScope
        )
        let metadata = existingMetadata ?? StoredCloudKitRecordMetadata(
            storageKey: storageKey,
            recordName: recordID.recordName,
            zoneName: recordID.zoneID.zoneName,
            ownerName: recordID.zoneID.ownerName,
            databaseScopeRawValue: Self.databaseScopeRawValue(databaseScope),
            systemFieldsData: systemFieldsData
        )

        metadata.recordName = recordID.recordName
        metadata.zoneName = recordID.zoneID.zoneName
        metadata.ownerName = recordID.zoneID.ownerName
        metadata.databaseScopeRawValue = Self.databaseScopeRawValue(databaseScope)
        metadata.systemFieldsData = systemFieldsData

        if existingMetadata == nil {
            modelContext.insert(metadata)
        }

        try modelContext.save()
    }

    public func deleteSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws {
        guard let metadata = try fetchMetadata(
            for: recordID,
            databaseScope: databaseScope
        ) else {
            return
        }

        modelContext.delete(metadata)
        try modelContext.save()
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
    }

    private func fetchMetadata(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws -> StoredCloudKitRecordMetadata? {
        let storageKey = Self.storageKey(
            for: recordID,
            databaseScope: databaseScope
        )
        return try modelContext.fetch(FetchDescriptor<StoredCloudKitRecordMetadata>())
            .first(where: { $0.storageKey == storageKey })
    }

    private static func storageKey(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) -> String {
        [
            databaseScopeRawValue(databaseScope),
            recordID.zoneID.ownerName,
            recordID.zoneID.zoneName,
            recordID.recordName,
        ].joined(separator: "|")
    }

    private static func databaseScopeRawValue(_ databaseScope: CKDatabase.Scope) -> String {
        switch databaseScope {
        case .private:
            "private"
        case .shared:
            "shared"
        case .public:
            "public"
        @unknown default:
            "unknown"
        }
    }
}
