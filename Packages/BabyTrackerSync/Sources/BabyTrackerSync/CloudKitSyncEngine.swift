import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation

@MainActor
public final class CloudKitSyncEngine {
    public private(set) var statusSummary = SyncStatusSummary()

    private let childRepository: ChildProfileRepository
    private let eventRepository: EventRepository
    private let syncStateRepository: SyncStateRepository
    private let client: CloudKitClient

    private var pendingInvitesByChildID: [UUID: [CloudKitPendingInvite]] = [:]

    public init(
        childRepository: ChildProfileRepository,
        eventRepository: EventRepository,
        syncStateRepository: SyncStateRepository,
        client: CloudKitClient = LiveCloudKitClient()
    ) {
        self.childRepository = childRepository
        self.eventRepository = eventRepository
        self.syncStateRepository = syncStateRepository
        self.client = client
    }

    public func prepareForLaunch() async -> SyncStatusSummary {
        await refresh(reason: .launch)
    }

    public func refreshAfterLocalWrite() async -> SyncStatusSummary {
        await refresh(reason: .localWrite)
    }

    public func refreshForeground() async -> SyncStatusSummary {
        await refresh(reason: .foreground)
    }

    public func pendingInvites(for childID: UUID) -> [CloudKitPendingInvite] {
        pendingInvitesByChildID[childID] ?? []
    }

    public func prepareShare(
        for childID: UUID
    ) async throws -> CloudKitSharePresentation {
        guard let container = client.container else {
            throw CKError(.notAuthenticated)
        }

        let zoneContext = try await ensureZoneContext(for: childID, preferredScope: .private)
        try await pushZoneSnapshot(for: childID, context: zoneContext)

        let shareRecordID = CloudKitRecordNames.shareRecordID(
            childID: childID,
            zoneID: zoneContext.zoneID
        )
        let childRecordID = CloudKitRecordNames.childRecordID(
            childID: childID,
            zoneID: zoneContext.zoneID
        )

        let existingShare = try await client.records(
            for: [shareRecordID],
            databaseScope: .private
        )[shareRecordID] as? CKShare

        if let existingShare {
            cachePendingInvites(for: childID, share: existingShare)
            return CloudKitSharePresentation(
                share: existingShare,
                container: container
            )
        }

        guard let child = try childRepository.loadChild(id: childID) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let childRecord = try await client.records(
            for: [childRecordID],
            databaseScope: .private
        )[childRecordID] ?? CloudKitRecordMapper.childRecord(
            from: child,
            zoneID: zoneContext.zoneID
        )

        let share = CKShare(
            rootRecord: childRecord,
            shareID: shareRecordID
        )
        share[CKShare.SystemFieldKey.title] = CloudKitRecordMapper.shareTitle(for: child)

        _ = try await client.modifyRecords(
            saving: [childRecord, share],
            deleting: [],
            databaseScope: .private,
            savePolicy: .changedKeys
        )

        let savedContext = CloudKitChildContext(
            childID: childID,
            zoneID: zoneContext.zoneID,
            shareRecordName: shareRecordID.recordName,
            databaseScope: .private
        )
        try childRepository.saveCloudKitChildContext(savedContext)
        cachePendingInvites(for: childID, share: share)

        return CloudKitSharePresentation(
            share: share,
            container: container
        )
    }

    public func removeParticipant(
        membership: Membership
    ) async throws {
        guard let context = try childRepository.loadCloudKitChildContext(id: membership.childID) else {
            return
        }

        let shareRecordName = context.shareRecordName ?? CloudKitRecordNames.shareRecordID(
            childID: membership.childID,
            zoneID: context.zoneID
        ).recordName
        let shareRecordID = CKRecord.ID(
            recordName: shareRecordName,
            zoneID: context.zoneID
        )

        guard let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare else {
            return
        }

        let users = try childRepository.loadUsers(for: [membership.userID])
        let cloudRecordName = users.first?.cloudKitUserRecordName

        if let participant = share.participants.first(where: { participant in
            participant.userIdentity.userRecordID?.recordName == cloudRecordName
        }) {
            share.removeParticipant(participant)
            _ = try await client.modifyRecords(
                saving: [share],
                deleting: [],
                databaseScope: context.databaseScope,
                savePolicy: .changedKeys
            )
        }

        cachePendingInvites(for: membership.childID, share: share)
        _ = await refresh(reason: .foreground)
    }

    public func accept(metadata: CKShare.Metadata) async throws {
        try await client.accept([metadata])
        _ = await refresh(reason: .foreground)
        try await ensureMembershipForAcceptedShare(metadata: metadata)
        _ = await refresh(reason: .localWrite)
    }

    private func refresh(reason: RefreshReason) async -> SyncStatusSummary {
        do {
            try childRepository.removeLegacyPlaceholderCaregivers()
            let accountStatus = try await client.accountStatus()

            guard accountStatus == .available else {
                statusSummary = try syncUnavailableSummary(for: accountStatus)
                return statusSummary
            }

            let userRecordID = try await client.userRecordID()
            _ = try childRepository.linkLocalUser(
                toCloudKitUserRecordName: userRecordID.recordName
            )

            try await pullSharedDatabaseChanges()
            try await pullKnownChildZones()

            if reason != .launch {
                try await pushPendingChanges()
            } else {
                try await pushPendingChanges()
            }

            statusSummary = try syncStateRepository.loadStatusSummary()
            return statusSummary
        } catch {
            let localSummary = (try? syncStateRepository.loadStatusSummary()) ?? SyncStatusSummary()
            statusSummary = SyncStatusSummary(
                state: .failed,
                pendingRecordCount: localSummary.pendingRecordCount,
                lastSyncAt: localSummary.lastSyncAt,
                lastErrorDescription: error.localizedDescription
            )
            return statusSummary
        }
    }

    private func syncUnavailableSummary(for accountStatus: CKAccountStatus) throws -> SyncStatusSummary {
        let localSummary = try syncStateRepository.loadStatusSummary()
        return SyncStatusSummary(
            state: .failed,
            pendingRecordCount: localSummary.pendingRecordCount,
            lastSyncAt: localSummary.lastSyncAt,
            lastErrorDescription: accountStatus == .noAccount ? "Sync unavailable. Sign in to iCloud." : "Sync unavailable right now."
        )
    }

    private func pullSharedDatabaseChanges() async throws {
        let anchor = try syncStateRepository.loadAnchor(
            databaseScope: "shared",
            zoneName: nil,
            ownerName: nil
        )
        let changes = try await client.databaseChanges(
            in: .shared,
            since: anchor?.tokenData
        )

        for deletedZoneID in changes.deletedZoneIDs {
            let childID = childID(from: deletedZoneID.zoneName)
            try childRepository.purgeChildData(id: childID)
            pendingInvitesByChildID[childID] = []
        }

        for zoneID in changes.modifiedZoneIDs {
            let childID = childID(from: zoneID.zoneName)
            let context = CloudKitChildContext(
                childID: childID,
                zoneID: zoneID,
                shareRecordName: CloudKitRecordNames.shareRecordID(
                    childID: childID,
                    zoneID: zoneID
                ).recordName,
                databaseScope: .shared
            )
            try childRepository.saveCloudKitChildContext(context)
            try await pullZoneSnapshot(context: context)
        }

        let newAnchor = SyncAnchor(
            databaseScope: .shared,
            zoneID: nil,
            tokenData: changes.tokenData,
            lastSyncAt: .now
        )
        try syncStateRepository.saveAnchor(newAnchor)
    }

    private func pullKnownChildZones() async throws {
        let children = try childRepository.loadAllChildren()

        for child in children {
            let context = try childRepository.loadCloudKitChildContext(id: child.id) ??
                CloudKitChildContext(
                    childID: child.id,
                    zoneID: CloudKitRecordNames.zoneID(for: child.id),
                    shareRecordName: CloudKitRecordNames.shareRecordID(
                        childID: child.id,
                        zoneID: CloudKitRecordNames.zoneID(for: child.id)
                    ).recordName,
                    databaseScope: .private
                )
            try await pullZoneSnapshot(context: context)
        }
    }

    private func pushPendingChanges() async throws {
        let pendingRecords = try syncStateRepository.loadPendingRecords()
        let pendingUserIDs = Set(
            pendingRecords
                .filter { $0.recordType == .user }
                .map(\.recordID)
        )

        let children = try childRepository.loadAllChildren()
        for child in children {
            let memberships = try childRepository.loadMemberships(for: child.id)
            let childHasPending = pendingRecords.contains { $0.childID == child.id || $0.recordID == child.id }
            let childHasPendingUsers = memberships.contains { pendingUserIDs.contains($0.userID) }

            guard childHasPending || childHasPendingUsers else {
                continue
            }

            let context = try await ensureZoneContext(for: child.id, preferredScope: .private)
            try await pushZoneSnapshot(for: child.id, context: context)
        }
    }

    private func pushZoneSnapshot(
        for childID: UUID,
        context: CloudKitChildContext
    ) async throws {
        guard let child = try childRepository.loadChild(id: childID) else {
            return
        }

        let memberships = try childRepository.loadMemberships(for: childID)
        let users = try childRepository.loadUsers(for: memberships.map(\.userID) + [child.createdBy])
        let events = try eventRepository.loadTimeline(
            for: childID,
            includingDeleted: true
        )

        let childRecord = CloudKitRecordMapper.childRecord(from: child, zoneID: context.zoneID)
        var recordsToSave: [CKRecord] = [childRecord]
        recordsToSave.append(contentsOf: users.map { CloudKitRecordMapper.userRecord(from: $0, zoneID: context.zoneID) })
        recordsToSave.append(contentsOf: memberships.map { CloudKitRecordMapper.membershipRecord(from: $0, zoneID: context.zoneID) })
        recordsToSave.append(contentsOf: events.map { CloudKitRecordMapper.eventRecord(from: $0, zoneID: context.zoneID) })

        let existingRecords = try await client.records(
            for: recordsToSave.map(\.recordID),
            databaseScope: context.databaseScope
        )

        var filteredSaves: [CKRecord] = []
        for record in recordsToSave {
            if let remoteRecord = existingRecords[record.recordID],
               let localEvent = try? event(from: record),
               let remoteEvent = try? event(from: remoteRecord),
               !LastWriteWinsResolver.prefersLocal(localEvent.metadata, over: remoteEvent.metadata) {
                try eventRepository.saveEvent(remoteEvent)
                try syncStateRepository.updateSyncState(
                    for: SyncRecordReference(
                        recordType: recordType(for: remoteEvent),
                        recordID: remoteEvent.id,
                        childID: remoteEvent.metadata.childID
                    ),
                    state: .upToDate,
                    lastSyncedAt: .now,
                    lastSyncErrorCode: nil
                )
                continue
            }

            filteredSaves.append(record)
        }

        _ = try await client.modifyRecords(
            saving: filteredSaves,
            deleting: [],
            databaseScope: context.databaseScope,
            savePolicy: .changedKeys
        )

        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )

        for membership in memberships {
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(
                    recordType: .membership,
                    recordID: membership.id,
                    childID: childID
                ),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        for user in users {
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(recordType: .user, recordID: user.id),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        for event in events {
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(
                    recordType: recordType(for: event),
                    recordID: event.id,
                    childID: event.metadata.childID
                ),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        let shareRecordID = CKRecord.ID(
            recordName: context.shareRecordName ?? CloudKitRecordNames.shareRecordID(
                childID: childID,
                zoneID: context.zoneID
            ).recordName,
            zoneID: context.zoneID
        )
        if let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare {
            cachePendingInvites(for: childID, share: share)
        }
    }

    private func pullZoneSnapshot(context: CloudKitChildContext) async throws {
        let childRecords = try await loadRecords(
            recordType: CloudKitConfiguration.childRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let userRecords = try await loadRecords(
            recordType: CloudKitConfiguration.userRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let membershipRecords = try await loadRecords(
            recordType: CloudKitConfiguration.membershipRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let breastFeedRecords = try await loadRecords(
            recordType: CloudKitConfiguration.breastFeedRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let bottleFeedRecords = try await loadRecords(
            recordType: CloudKitConfiguration.bottleFeedRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let sleepRecords = try await loadRecords(
            recordType: CloudKitConfiguration.sleepRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )
        let nappyRecords = try await loadRecords(
            recordType: CloudKitConfiguration.nappyRecordType,
            zoneID: context.zoneID,
            scope: context.databaseScope
        )

        for record in childRecords {
            let child = try CloudKitRecordMapper.child(from: record)
            try childRepository.saveChild(child)
            let updatedContext = CloudKitChildContext(
                childID: child.id,
                zoneID: context.zoneID,
                shareRecordName: context.shareRecordName,
                databaseScope: context.databaseScope
            )
            try childRepository.saveCloudKitChildContext(updatedContext)
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        for record in userRecords {
            let user = try CloudKitRecordMapper.user(from: record)
            try childRepository.saveUser(user)
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(recordType: .user, recordID: user.id),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        for record in membershipRecords {
            let membership = CloudKitRecordMapper.membership(from: record)
            try childRepository.saveMembership(membership)
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(
                    recordType: .membership,
                    recordID: membership.id,
                    childID: membership.childID
                ),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }

        try await saveEvents(from: breastFeedRecords)
        try await saveEvents(from: bottleFeedRecords)
        try await saveEvents(from: sleepRecords)
        try await saveEvents(from: nappyRecords)

        let childID = context.childID
        let shareRecordID = CKRecord.ID(
            recordName: context.shareRecordName ?? CloudKitRecordNames.shareRecordID(
                childID: childID,
                zoneID: context.zoneID
            ).recordName,
            zoneID: context.zoneID
        )
        if let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare {
            cachePendingInvites(for: childID, share: share)
        }
    }

    private func saveEvents(from records: [CKRecord]) async throws {
        for record in records {
            let event = try CloudKitRecordMapper.event(from: record)
            try eventRepository.saveEvent(event)
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(
                    recordType: recordType(for: event),
                    recordID: event.id,
                    childID: event.metadata.childID
                ),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        }
    }

    private func ensureZoneContext(
        for childID: UUID,
        preferredScope: CKDatabase.Scope
    ) async throws -> CloudKitChildContext {
        if let existing = try childRepository.loadCloudKitChildContext(id: childID) {
            return existing
        }

        let zoneID = CloudKitRecordNames.zoneID(for: childID)
        let existingZones = try await client.recordZones(
            for: [zoneID],
            databaseScope: preferredScope
        )

        if existingZones[zoneID] == nil {
            try await client.modifyRecordZones(
                saving: [CKRecordZone(zoneID: zoneID)],
                deleting: [],
                databaseScope: preferredScope
            )
        }

        let context = CloudKitChildContext(
            childID: childID,
            zoneID: zoneID,
            shareRecordName: CloudKitRecordNames.shareRecordID(
                childID: childID,
                zoneID: zoneID
            ).recordName,
            databaseScope: preferredScope
        )
        try childRepository.saveCloudKitChildContext(context)
        return context
    }

    private func loadRecords(
        recordType: String,
        zoneID: CKRecordZone.ID,
        scope: CKDatabase.Scope
    ) async throws -> [CKRecord] {
        let query = CKQuery(
            recordType: recordType,
            predicate: NSPredicate(value: true)
        )

        return try await client.records(
            matching: query,
            in: zoneID,
            databaseScope: scope
        )
    }

    private func ensureMembershipForAcceptedShare(
        metadata: CKShare.Metadata
    ) async throws {
        guard let localUser = try childRepository.loadLocalUser() else {
            return
        }

        guard let rootRecordID = metadata.hierarchicalRootRecordID else {
            return
        }

        let childID = childID(fromRecordName: rootRecordID.recordName)
        let existingMemberships = try childRepository.loadMemberships(for: childID)
        guard !existingMemberships.contains(where: { membership in
            membership.userID == localUser.id && membership.status == .active
        }) else {
            return
        }

        let membership = Membership(
            childID: childID,
            userID: localUser.id,
            role: .caregiver,
            status: .active,
            invitedAt: .now,
            acceptedAt: .now
        )

        try childRepository.saveUser(localUser)
        try childRepository.saveMembership(membership)
        let context = CloudKitChildContext(
            childID: childID,
            zoneID: rootRecordID.zoneID,
            shareRecordName: metadata.share.recordID.recordName,
            databaseScope: .shared
        )
        try childRepository.saveCloudKitChildContext(context)
    }

    private func cachePendingInvites(
        for childID: UUID,
        share: CKShare
    ) {
        pendingInvitesByChildID[childID] = share.participants
            .filter { participant in
                participant.role != .owner &&
                participant.acceptanceStatus != .accepted
            }
            .map { participant in
                CloudKitPendingInvite(
                    childID: childID,
                    participantID: participant.participantID,
                    displayName: participantDisplayName(participant),
                    acceptanceStatus: participant.acceptanceStatus
                )
            }
    }

    private func participantDisplayName(_ participant: CKShare.Participant) -> String {
        if let components = participant.userIdentity.nameComponents {
            let formatter = PersonNameComponentsFormatter()
            let formatted = formatter.string(from: components)
            if !formatted.isEmpty {
                return formatted
            }
        }

        if let emailAddress = participant.userIdentity.lookupInfo?.emailAddress {
            return emailAddress
        }

        if let phoneNumber = participant.userIdentity.lookupInfo?.phoneNumber {
            return phoneNumber
        }

        return "Pending invitation"
    }

    private func childID(from zoneName: String) -> UUID {
        let rawValue = zoneName.replacingOccurrences(of: "child-", with: "")
        return UUID(uuidString: rawValue) ?? UUID()
    }

    private func childID(fromRecordName recordName: String) -> UUID {
        let rawValue = recordName.replacingOccurrences(of: "child.", with: "")
        return UUID(uuidString: rawValue) ?? UUID()
    }

    private func event(from record: CKRecord) throws -> BabyEvent {
        try CloudKitRecordMapper.event(from: record)
    }

    private func recordType(for event: BabyEvent) -> SyncRecordType {
        switch event.kind {
        case .breastFeed:
            .breastFeedEvent
        case .bottleFeed:
            .bottleFeedEvent
        case .sleep:
            .sleepEvent
        case .nappy:
            .nappyEvent
        }
    }
}

extension CloudKitSyncEngine {
    private enum RefreshReason {
        case launch
        case foreground
        case localWrite
    }
}
