import BabyTrackerDomain
import CloudKit
import Foundation
import SwiftData

@MainActor
public final class SwiftDataChildRepository: CloudKitChildRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public func loadAllChildren() throws -> [Child] {
        try modelContext.fetch(FetchDescriptor<StoredChild>())
            .map(mapChild)
            .sorted(by: sortChildren)
    }

    public func loadActiveChildren(for userID: UUID) throws -> [Child] {
        try loadChildren(for: userID, isArchived: false)
    }

    public func loadArchivedChildren(for userID: UUID) throws -> [Child] {
        try loadChildren(for: userID, isArchived: true)
    }

    public func loadChild(id: UUID) throws -> Child? {
        guard let storedChild = try fetchStoredChild(id: id) else {
            return nil
        }

        return try mapChild(storedChild)
    }

    public func saveChild(_ child: Child) throws {
        let existingStoredChild = try fetchStoredChild(id: child.id)
        let storedChild = existingStoredChild ?? StoredChild(
            id: child.id,
            name: child.name,
            birthDate: child.birthDate,
            createdAt: child.createdAt,
            createdBy: child.createdBy,
            isArchived: child.isArchived
        )

        storedChild.name = child.name
        storedChild.birthDate = child.birthDate
        storedChild.createdAt = child.createdAt
        storedChild.createdBy = child.createdBy
        storedChild.isArchived = child.isArchived
        storedChild.imageData = child.imageData
        storedChild.preferredFeedVolumeUnitRawValue = child.preferredFeedVolumeUnit.rawValue
        markPendingSync(storedChild, errorCode: nil)

        if existingStoredChild == nil {
            modelContext.insert(storedChild)
        }

        try saveChanges()
    }

    public func loadCloudKitChildContext(id: UUID) throws -> CloudKitChildContext? {
        guard let storedChild = try fetchStoredChild(id: id),
              let zoneName = storedChild.cloudKitZoneName,
              let ownerName = storedChild.cloudKitZoneOwnerName,
              let databaseScopeRawValue = storedChild.cloudKitDatabaseScopeRawValue else {
            return nil
        }

        return CloudKitChildContext(
            childID: id,
            zoneID: CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName),
            shareRecordName: storedChild.cloudKitShareRecordName,
            databaseScope: databaseScopeRawValue == "shared" ? .shared : .private
        )
    }

    public func saveCloudKitChildContext(_ context: CloudKitChildContext) throws {
        guard let storedChild = try fetchStoredChild(id: context.childID) else {
            return
        }

        storedChild.cloudKitZoneName = context.zoneID.zoneName
        storedChild.cloudKitZoneOwnerName = context.zoneID.ownerName
        storedChild.cloudKitShareRecordName = context.shareRecordName
        storedChild.cloudKitDatabaseScopeRawValue = context.databaseScope == .shared ? "shared" : "private"
        try saveChanges()
    }

    /// Deletes all data associated with a child: memberships, all event types, and the child record itself.
    /// Does not clear the selected child preference — callers are responsible for that.
    public func purgeChildData(id: UUID) throws {
        for membership in try modelContext.fetch(FetchDescriptor<StoredMembership>()) where membership.childID == id {
            modelContext.delete(membership)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        for event in try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()) where event.childID == id {
            modelContext.delete(event)
        }

        if let child = try fetchStoredChild(id: id) {
            modelContext.delete(child)
        }

        try saveChanges()
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
    }

    private func loadChildren(for userID: UUID, isArchived: Bool) throws -> [Child] {
        let activeChildIDs = Set(
            try modelContext.fetch(FetchDescriptor<StoredMembership>())
                .filter { membership in
                    membership.userID == userID &&
                    membership.statusRawValue == MembershipStatus.active.rawValue
                }
                .map(\.childID)
        )

        return try modelContext.fetch(FetchDescriptor<StoredChild>())
            .filter { child in
                activeChildIDs.contains(child.id) && child.isArchived == isArchived
            }
            .map(mapChild)
            .sorted(by: sortChildren)
    }

    private func fetchStoredChild(id: UUID) throws -> StoredChild? {
        try modelContext.fetch(FetchDescriptor<StoredChild>())
            .first { $0.id == id }
    }

    private func mapChild(_ storedChild: StoredChild) throws -> Child {
        try Child(
            id: storedChild.id,
            name: storedChild.name,
            birthDate: storedChild.birthDate,
            createdAt: storedChild.createdAt,
            createdBy: storedChild.createdBy,
            isArchived: storedChild.isArchived,
            imageData: storedChild.imageData,
            preferredFeedVolumeUnit: FeedVolumeUnit(rawValue: storedChild.preferredFeedVolumeUnitRawValue) ?? .milliliters
        )
    }

    private func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }

    private func sortChildren(_ left: Child, _ right: Child) -> Bool {
        left.createdAt < right.createdAt
    }

    private func markPendingSync(_ storedModel: StoredChild, errorCode: String?) {
        storedModel.syncStateRawValue = SyncState.pendingSync.rawValue
        storedModel.lastSyncErrorCode = errorCode
    }
}
