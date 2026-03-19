import BabyTrackerDomain
import CloudKit
import Foundation
import SwiftData

@MainActor
public final class SwiftDataSyncStateRepository: SyncStateRepository {
    private let store: BabyTrackerModelStore

    public init(store: BabyTrackerModelStore) {
        self.store = store
    }

    public convenience init(isStoredInMemoryOnly: Bool = false) throws {
        let store = try BabyTrackerModelStore(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        self.init(store: store)
    }

    public func loadPendingRecords() throws -> [SyncRecordReference] {
        var records: [SyncRecordReference] = []

        records.append(contentsOf: try pendingChildren())
        records.append(contentsOf: try pendingUsers())
        records.append(contentsOf: try pendingMemberships())
        records.append(contentsOf: try pendingBreastFeeds())
        records.append(contentsOf: try pendingBottleFeeds())
        records.append(contentsOf: try pendingSleepEvents())
        records.append(contentsOf: try pendingNappyEvents())

        return records
    }

    public func updateSyncState(
        for record: SyncRecordReference,
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?
    ) throws {
        switch record.recordType {
        case .child:
            if let model = try fetchChild(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .user:
            if let model = try fetchUser(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .membership:
            if let model = try fetchMembership(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .breastFeedEvent:
            if let model = try fetchBreastFeed(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .bottleFeedEvent:
            if let model = try fetchBottleFeed(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .sleepEvent:
            if let model = try fetchSleep(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        case .nappyEvent:
            if let model = try fetchNappy(id: record.recordID) {
                apply(state: state, lastSyncedAt: lastSyncedAt, lastSyncErrorCode: lastSyncErrorCode, to: model)
            }
        }

        try saveChanges()
    }

    public func saveAnchor(_ anchor: SyncAnchor) throws {
        let databaseScope = anchor.databaseScope == .shared ? "shared" : "private"
        let existingAnchor = try fetchAnchor(
            databaseScope: databaseScope,
            zoneName: anchor.zoneID?.zoneName,
            ownerName: anchor.zoneID?.ownerName
        )
        let storedAnchor = existingAnchor ?? StoredSyncAnchor(
            databaseScope: databaseScope,
            zoneName: anchor.zoneID?.zoneName,
            ownerName: anchor.zoneID?.ownerName,
            tokenData: anchor.tokenData,
            lastSyncAt: anchor.lastSyncAt
        )

        storedAnchor.databaseScope = databaseScope
        storedAnchor.zoneName = anchor.zoneID?.zoneName
        storedAnchor.ownerName = anchor.zoneID?.ownerName
        storedAnchor.tokenData = anchor.tokenData
        storedAnchor.lastSyncAt = anchor.lastSyncAt

        if existingAnchor == nil {
            modelContext.insert(storedAnchor)
        }

        try saveChanges()
    }

    public func loadAnchor(
        databaseScope: String,
        zoneName: String?,
        ownerName: String?
    ) throws -> SyncAnchor? {
        guard let storedAnchor = try fetchAnchor(
            databaseScope: databaseScope,
            zoneName: zoneName,
            ownerName: ownerName
        ) else {
            return nil
        }

        return SyncAnchor(
            databaseScope: databaseScope.contains("shared") ? .shared : .private,
            zoneID: zoneName.map { zoneName in
                CKRecordZone.ID(
                    zoneName: zoneName,
                    ownerName: ownerName ?? CKCurrentUserDefaultName
                )
            },
            tokenData: storedAnchor.tokenData,
            lastSyncAt: storedAnchor.lastSyncAt
        )
    }

    public func loadStatusSummary() throws -> SyncStatusSummary {
        let syncStates = try allSyncStates()
        let pendingCount = syncStates.filter { $0 == .pendingSync }.count
        let lastSyncAt = try allLastSyncedAt()
            .compactMap { $0 }
            .max()
        let lastErrorDescription = try allLastErrorCodes()
            .compactMap { $0 }
            .last

        let state: SyncState
        if syncStates.contains(.syncing) {
            state = .syncing
        } else if syncStates.contains(.failed) {
            state = .failed
        } else if syncStates.contains(.pendingSync) {
            state = .pendingSync
        } else {
            state = .upToDate
        }

        return SyncStatusSummary(
            state: state,
            pendingRecordCount: pendingCount,
            lastSyncAt: lastSyncAt,
            lastErrorDescription: lastErrorDescription
        )
    }

    private var modelContext: ModelContext {
        store.modelContainer.mainContext
    }

    private func pendingChildren() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredChild>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .child, recordID: $0.id, childID: $0.id) }
    }

    private func pendingUsers() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .user, recordID: $0.id) }
    }

    private func pendingMemberships() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredMembership>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .membership, recordID: $0.id, childID: $0.childID) }
    }

    private func pendingBreastFeeds() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .breastFeedEvent, recordID: $0.id, childID: $0.childID) }
    }

    private func pendingBottleFeeds() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .bottleFeedEvent, recordID: $0.id, childID: $0.childID) }
    }

    private func pendingSleepEvents() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredSleepEvent>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .sleepEvent, recordID: $0.id, childID: $0.childID) }
    }

    private func pendingNappyEvents() throws -> [SyncRecordReference] {
        try modelContext.fetch(FetchDescriptor<StoredNappyEvent>())
            .filter { $0.syncStateRawValue == SyncState.pendingSync.rawValue }
            .map { SyncRecordReference(recordType: .nappyEvent, recordID: $0.id, childID: $0.childID) }
    }

    private func fetchChild(id: UUID) throws -> StoredChild? {
        try modelContext.fetch(FetchDescriptor<StoredChild>()).first { $0.id == id }
    }

    private func fetchUser(id: UUID) throws -> StoredUserIdentity? {
        try modelContext.fetch(FetchDescriptor<StoredUserIdentity>()).first { $0.id == id }
    }

    private func fetchMembership(id: UUID) throws -> StoredMembership? {
        try modelContext.fetch(FetchDescriptor<StoredMembership>()).first { $0.id == id }
    }

    private func fetchBreastFeed(id: UUID) throws -> StoredBreastFeedEvent? {
        try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()).first { $0.id == id }
    }

    private func fetchBottleFeed(id: UUID) throws -> StoredBottleFeedEvent? {
        try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()).first { $0.id == id }
    }

    private func fetchSleep(id: UUID) throws -> StoredSleepEvent? {
        try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()).first { $0.id == id }
    }

    private func fetchNappy(id: UUID) throws -> StoredNappyEvent? {
        try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()).first { $0.id == id }
    }

    private func fetchAnchor(
        databaseScope: String,
        zoneName: String?,
        ownerName: String?
    ) throws -> StoredSyncAnchor? {
        try modelContext.fetch(FetchDescriptor<StoredSyncAnchor>())
            .first { anchor in
                anchor.databaseScope == databaseScope &&
                anchor.zoneName == zoneName &&
                anchor.ownerName == ownerName
            }
    }

    private func allSyncStates() throws -> [SyncState] {
        var rawValues: [String] = []

        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredChild>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredUserIdentity>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredMembership>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredSleepEvent>()).map(\.syncStateRawValue))
        rawValues.append(contentsOf: try modelContext.fetch(FetchDescriptor<StoredNappyEvent>()).map(\.syncStateRawValue))

        return rawValues.compactMap(SyncState.init(rawValue:))
    }

    private func allLastSyncedAt() throws -> [Date?] {
        try modelContext.fetch(FetchDescriptor<StoredChild>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredUserIdentity>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredMembership>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredSleepEvent>()).map(\.lastSyncedAt) +
            modelContext.fetch(FetchDescriptor<StoredNappyEvent>()).map(\.lastSyncedAt)
    }

    private func allLastErrorCodes() throws -> [String?] {
        try modelContext.fetch(FetchDescriptor<StoredChild>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredUserIdentity>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredMembership>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredBreastFeedEvent>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredBottleFeedEvent>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredSleepEvent>()).map(\.lastSyncErrorCode) +
            modelContext.fetch(FetchDescriptor<StoredNappyEvent>()).map(\.lastSyncErrorCode)
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredChild
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredUserIdentity
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredMembership
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredBreastFeedEvent
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredBottleFeedEvent
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredSleepEvent
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func apply(
        state: SyncState,
        lastSyncedAt: Date?,
        lastSyncErrorCode: String?,
        to model: StoredNappyEvent
    ) {
        model.syncStateRawValue = state.rawValue
        model.lastSyncedAt = lastSyncedAt
        model.lastSyncErrorCode = lastSyncErrorCode
    }

    private func saveChanges() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
