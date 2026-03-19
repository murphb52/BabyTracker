import Foundation
import SwiftData

@Model
final class StoredChild {
    var id: UUID = UUID()
    var name: String = ""
    var birthDate: Date?
    var createdAt: Date = Date()
    var createdBy: UUID = UUID()
    var isArchived: Bool = false

    init(
        id: UUID,
        name: String,
        birthDate: Date?,
        createdAt: Date,
        createdBy: UUID,
        isArchived: Bool
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.isArchived = isArchived
    }
}
