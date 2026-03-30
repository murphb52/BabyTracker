import Foundation

public struct SyncRecordReference: Equatable, Hashable, Sendable {
    public let recordType: SyncRecordType
    public let recordID: UUID
    public let childID: UUID?

    public init(
        recordType: SyncRecordType,
        recordID: UUID,
        childID: UUID? = nil
    ) {
        self.recordType = recordType
        self.recordID = recordID
        self.childID = childID
    }
}
