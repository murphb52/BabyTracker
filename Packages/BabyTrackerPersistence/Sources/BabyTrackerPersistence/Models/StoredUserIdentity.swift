import Foundation
import SwiftData

@Model
final class StoredUserIdentity {
    var id: UUID = UUID()
    var displayName: String = ""
    var createdAt: Date = Date()
    var cloudKitUserRecordName: String?

    init(
        id: UUID,
        displayName: String,
        createdAt: Date,
        cloudKitUserRecordName: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
        self.cloudKitUserRecordName = cloudKitUserRecordName
    }
}
