import BabyTrackerPersistence
import CloudKit
import Foundation

/// In-memory test double for CloudKitRecordMetadataRepository.
/// Stores CloudKit system fields keyed by record ID and database scope.
@MainActor
final class InMemoryCloudKitRecordMetadataRepository: CloudKitRecordMetadataRepository {
    private var systemFields: [String: Data] = [:]

    func loadSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws -> Data? {
        systemFields[key(for: recordID, scope: databaseScope)]
    }

    func saveSystemFields(
        _ systemFieldsData: Data,
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws {
        systemFields[key(for: recordID, scope: databaseScope)] = systemFieldsData
    }

    func deleteSystemFields(
        for recordID: CKRecord.ID,
        databaseScope: CKDatabase.Scope
    ) throws {
        systemFields.removeValue(forKey: key(for: recordID, scope: databaseScope))
    }

    private func key(for recordID: CKRecord.ID, scope: CKDatabase.Scope) -> String {
        let scopeString = scope == .shared ? "shared" : "private"
        return "\(recordID.recordName)-\(recordID.zoneID.zoneName)-\(scopeString)"
    }
}
