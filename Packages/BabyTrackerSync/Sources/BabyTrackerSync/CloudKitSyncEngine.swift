import BabyTrackerDomain
import BabyTrackerPersistence
import CloudKit
import Foundation
import os

@MainActor
public final class CloudKitSyncEngine {
    public private(set) var statusSummary = SyncStatusSummary()

    enum ShareAcceptanceError: LocalizedError {
        case refreshFailed(String?)

        var errorDescription: String? {
            switch self {
            case let .refreshFailed(message):
                return message ?? "Sync failed while loading the accepted share."
            }
        }
    }

    private let childRepository: any CloudKitChildRepository
    private let userIdentityRepository: any CloudKitUserIdentityRepository
    private let membershipRepository: any CloudKitMembershipRepository
    private let eventRepository: EventRepository
    private let syncStateRepository: SyncStateRepository
    private let recordMetadataRepository: any CloudKitRecordMetadataRepository
    private let client: CloudKitClient

    private var pendingInvitesByChildID: [UUID: [CloudKitPendingInvite]] = [:]
    private var hasEnsuredDatabaseSubscriptions = false
    private var ensuredPrivateZoneSubscriptionIDs: Set<String> = []
    private var remoteCaregiverEventChanges: [RemoteCaregiverEventChange] = []
    private var shouldCollectRemoteCaregiverEvents = false
    private var currentLocalUserID: UUID?
    private var cachedUserDisplayNames: [UUID: String] = [:]

    private let logger = Logger(subsystem: "com.adappt.BabyTracker", category: "CloudKitSync")

    public init(
        childRepository: any CloudKitChildRepository,
        userIdentityRepository: any CloudKitUserIdentityRepository,
        membershipRepository: any CloudKitMembershipRepository,
        eventRepository: EventRepository,
        syncStateRepository: SyncStateRepository,
        recordMetadataRepository: any CloudKitRecordMetadataRepository,
        client: CloudKitClient = LiveCloudKitClient()
    ) {
        self.childRepository = childRepository
        self.userIdentityRepository = userIdentityRepository
        self.membershipRepository = membershipRepository
        self.eventRepository = eventRepository
        self.syncStateRepository = syncStateRepository
        self.recordMetadataRepository = recordMetadataRepository
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

    public func forceFullRefresh() async -> SyncStatusSummary {
        await refresh(reason: .manualFullRefresh)
    }

    public func refreshAfterRemoteNotification() async -> SyncStatusSummary {
        await refresh(reason: .remoteNotification)
    }

    public func pendingInvites(for childID: UUID) -> [CloudKitPendingInvite] {
        pendingInvitesByChildID[childID] ?? []
    }

    public func consumeRemoteCaregiverEventChanges() -> [RemoteCaregiverEventChange] {
        let changes = remoteCaregiverEventChanges
        remoteCaregiverEventChanges = []
        return changes
    }

    public func prepareShare(
        for childID: UUID
    ) async throws -> CloudKitSharePresentation {
        guard let container = client.container else {
            throw CKError(.notAuthenticated)
        }

        let zoneContext = try await ensureZoneContext(for: childID, preferredScope: .private)

        let legacyShareRecordID = CloudKitRecordNames.legacyShareRecordID(
            childID: childID,
            zoneID: zoneContext.zoneID
        )
        let zoneShareRecordID = CloudKitRecordNames.zoneShareRecordID(zoneID: zoneContext.zoneID)

        let fetched = try await client.records(
            for: [legacyShareRecordID, zoneShareRecordID],
            databaseScope: .private
        )
        let existingZoneShare = fetched[zoneShareRecordID] as? CKShare
        let existingLegacyShare = fetched[legacyShareRecordID] as? CKShare

        if let existingZoneShare {
            logger.info("prepareShare \(childID, privacy: .public): zone share already exists, returning existing share")
            AppLogger.shared.log(.info, category: "CloudKitSync", "prepareShare \(childID): zone share already exists, returning existing share")
            cachePendingInvites(for: childID, share: existingZoneShare)
            let updatedContext = CloudKitChildContext(
                childID: childID,
                zoneID: zoneContext.zoneID,
                shareRecordName: nil,
                databaseScope: .private
            )
            try childRepository.saveCloudKitChildContext(updatedContext)
            return CloudKitSharePresentation(share: existingZoneShare, container: container)
        }

        // Migrate: delete the old record-level share if present. Existing caregivers
        // will lose access and need to be re-invited after the migration.
        if existingLegacyShare != nil {
            logger.warning("prepareShare \(childID, privacy: .public): found legacy record-level share — deleting and replacing with zone share; existing caregivers will need to re-accept")
            AppLogger.shared.log(.warning, category: "CloudKitSync", "prepareShare \(childID): found legacy record-level share — deleting and replacing with zone share")
            _ = try await client.modifyRecords(
                saving: [],
                deleting: [legacyShareRecordID],
                databaseScope: .private,
                savePolicy: .changedKeys,
                atomically: true
            )
            logger.info("prepareShare \(childID, privacy: .public): legacy share deleted")
            AppLogger.shared.log(.info, category: "CloudKitSync", "prepareShare \(childID): legacy share deleted")
        }

        guard let child = try childRepository.loadChild(id: childID) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        try await ensureRemoteChildRecordExists(
            for: child,
            context: zoneContext
        )

        logger.info("prepareShare \(childID, privacy: .public): creating zone share")
        AppLogger.shared.log(.info, category: "CloudKitSync", "prepareShare \(childID): creating zone share")
        let share = CKShare(recordZoneID: zoneContext.zoneID)
        share[CKShare.SystemFieldKey.title] = CloudKitRecordMapper.shareTitle(for: child)

        _ = try await client.modifyRecords(
            saving: [share],
            deleting: [],
            databaseScope: .private,
            savePolicy: .changedKeys,
            atomically: true
        )
        logger.info("prepareShare \(childID, privacy: .public): zone share saved")
        AppLogger.shared.log(.info, category: "CloudKitSync", "prepareShare \(childID): zone share saved")

        let savedContext = CloudKitChildContext(
            childID: childID,
            zoneID: zoneContext.zoneID,
            shareRecordName: nil,
            databaseScope: .private
        )
        try childRepository.saveCloudKitChildContext(savedContext)
        cachePendingInvites(for: childID, share: share)

        return CloudKitSharePresentation(share: share, container: container)
    }

    public func removeParticipant(
        membership: Membership
    ) async throws {
        guard let context = try childRepository.loadCloudKitChildContext(id: membership.childID) else {
            return
        }

        let shareRecordID = context.shareRecordName.map {
            CKRecord.ID(recordName: $0, zoneID: context.zoneID)
        } ?? CloudKitRecordNames.zoneShareRecordID(zoneID: context.zoneID)

        guard let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare else {
            return
        }

        let users = try userIdentityRepository.loadUsers(for: [membership.userID])
        let cloudRecordName = users.first?.cloudKitUserRecordName

        if let participant = share.participants.first(where: { participant in
            participant.userIdentity.userRecordID?.recordName == cloudRecordName
        }) {
            share.removeParticipant(participant)
            _ = try await client.modifyRecords(
                saving: [share],
                deleting: [],
                databaseScope: context.databaseScope,
                savePolicy: .changedKeys,
                atomically: true
            )
        }

        cachePendingInvites(for: membership.childID, share: share)
        _ = await refresh(reason: .foreground)
    }

    public func loadPendingChangeCounts() throws -> [SyncRecordType: Int] {
        let pending = try syncStateRepository.loadPendingRecords()
        return Dictionary(grouping: pending, by: \.recordType).mapValues(\.count)
    }

    public func leaveShare(childID: UUID) async throws {
        guard let context = try childRepository.loadCloudKitChildContext(id: childID) else {
            return
        }
        guard context.databaseScope == .shared else {
            return
        }
        try await client.modifyRecordZones(
            saving: [],
            deleting: [context.zoneID],
            databaseScope: .shared
        )
        logger.info("Left shared zone for child \(childID)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "Left shared zone for child \(childID)")
    }

    public func hardDeleteChildCloudData(childID: UUID) async throws {
        let zoneID: CKRecordZone.ID
        if let context = try childRepository.loadCloudKitChildContext(id: childID) {
            // Only delete zones the user owns. Shared zones are owned by another user's
            // private database — attempting to delete them would fail with a permission
            // error. Caregivers should use leaveShare instead, and the caller (AppModel)
            // already guards against this, but we return early here as a safety net.
            guard context.databaseScope == .private else {
                logger.info("Skipping hard delete for shared zone of child \(childID) — not zone owner")
                AppLogger.shared.log(.info, category: "CloudKitSync", "Skipping hard delete for shared zone of child \(childID) — not zone owner")
                return
            }
            zoneID = context.zoneID
        } else {
            // Local context is missing (stale state). Fall back to the canonical zone name
            // so orphaned server-side zones are still cleaned up.
            zoneID = CloudKitRecordNames.zoneID(for: childID)
            logger.info("No local context for child \(childID) — attempting fallback zone delete")
            AppLogger.shared.log(.info, category: "CloudKitSync", "No local context for child \(childID) — attempting fallback zone delete")
        }

        do {
            try await client.modifyRecordZones(saving: [], deleting: [zoneID], databaseScope: .private)
            logger.info("Hard delete removed zone \(zoneID.zoneName, privacy: .public) for child \(childID)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Hard delete removed zone \(zoneID.zoneName) for child \(childID)")
        } catch let error as CKError where error.code == .zoneNotFound {
            // Zone was already deleted on the server — desired state is achieved.
            logger.info("Zone \(zoneID.zoneName, privacy: .public) already gone for child \(childID) — treating as success")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Zone \(zoneID.zoneName) already gone for child \(childID) — treating as success")
        }

        pendingInvitesByChildID[childID] = nil
    }

    public func accept(metadata: CKShare.Metadata) async throws {
        let shareTitle = metadata.share[CKShare.SystemFieldKey.title] as? String ?? "unknown"
        let zoneName = metadata.share.recordID.zoneID.zoneName
        print("[BabyTracker][4/5] CloudKitSyncEngine.accept — title: \(shareTitle), zone: \(zoneName)")
        logger.info("[4/5] Sync engine accept — title: '\(shareTitle, privacy: .private)', zone: \(zoneName, privacy: .public)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] Sync engine accept — title: '\(shareTitle)', zone: \(zoneName)")
        logger.info("[4/5] Calling client.accept (registers share with CloudKit)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] Calling client.accept (registers share with CloudKit)")
        try await client.accept([metadata])
        // Accepting the share registers access to the shared zone, but it does
        // not guarantee that the zone contents have been pulled locally yet.
        logger.info("[4/5] client.accept succeeded — forcing full pull of accepted shared zone")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] client.accept succeeded — forcing full pull of accepted shared zone")
        try await forcePullAcceptedShare(
            zoneID: metadata.share.recordID.zoneID,
            shareRecordName: metadata.share.recordID.recordName
        )
        logger.info("[4/5] Full accepted-share pull complete — running foreground refresh")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] Full accepted-share pull complete — running foreground refresh")
        try throwIfRefreshFailed(await refresh(reason: .foreground))
        logger.info("[4/5] Foreground refresh done — ensuring local membership record")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] Foreground refresh done — ensuring local membership record")
        try await ensureMembershipForAcceptedShare(metadata: metadata)
        logger.info("[4/5] Membership ensured — running post-write refresh")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] Membership ensured — running post-write refresh")
        try throwIfRefreshFailed(await refresh(reason: .localWrite))
        logger.info("[5/5] Share acceptance complete")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[5/5] Share acceptance complete")
    }

    private func refresh(reason: RefreshReason) async -> SyncStatusSummary {
        shouldCollectRemoteCaregiverEvents = reason == .remoteNotification
        remoteCaregiverEventChanges = []
        cachedUserDisplayNames = [:]
        currentLocalUserID = try? userIdentityRepository.loadLocalUser()?.id

        do {
            if reason == .launch {
                logger.info("Launch sync starting")
                AppLogger.shared.log(.info, category: "CloudKitSync", "Launch sync starting")
            }

            try userIdentityRepository.removeLegacyPlaceholderCaregivers()
            let accountStatus = try await client.accountStatus()

            if reason == .launch {
                logger.info("iCloud account status: \(accountStatus.logDescription, privacy: .public)")
                AppLogger.shared.log(.info, category: "CloudKitSync", "iCloud account status: \(accountStatus.logDescription)")
            }

            guard accountStatus == .available else {
                statusSummary = try syncUnavailableSummary(for: accountStatus)
                return statusSummary
            }

            let userRecordID = try await client.userRecordID()
            if reason == .launch {
                logger.info("iCloud user record ID: \(userRecordID.recordName, privacy: .private(mask: .hash))")
                AppLogger.shared.log(.info, category: "CloudKitSync", "iCloud user record ID obtained")
            }
            _ = try userIdentityRepository.linkLocalUser(
                toCloudKitUserRecordName: userRecordID.recordName
            )
            try await ensureDatabaseSubscriptions()

            try await pullSharedDatabaseChanges(forceFullFetch: reason == .manualFullRefresh)

            if reason == .localWrite {
                // Push local changes before pulling so a pending write (e.g. archive)
                // reaches CloudKit before the pull can overwrite the local state.
                try await pushPendingChanges()
                try await pullKnownChildZones(forceFullFetch: false)
            } else {
                try await pullKnownChildZones(forceFullFetch: reason == .manualFullRefresh)
                try await pushPendingChanges()
            }

            statusSummary = try syncStateRepository.loadStatusSummary()
            return statusSummary
        } catch {
            logger.error("Refresh(\(reason.logDescription, privacy: .public)) failed: \(error.localizedDescription, privacy: .public) [\(String(describing: error), privacy: .public)]")
            print("[BabyTracker] Refresh(\(reason.logDescription)) FAILED: \(error)")
            AppLogger.shared.log(.error, category: "CloudKitSync", "Refresh(\(reason.logDescription)) failed: \(error.localizedDescription)")
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

    private func ensureDatabaseSubscriptions() async throws {
        guard !hasEnsuredDatabaseSubscriptions else {
            return
        }

        for scope in [CKDatabase.Scope.shared] {
            let subscriptionID = CloudKitSubscriptionIDs.databaseSubscriptionID(for: scope)
            if try await client.subscription(withID: subscriptionID, databaseScope: scope) != nil {
                continue
            }

            let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            try await client.saveSubscription(subscription, databaseScope: scope)
            logger.info("Created CloudKit database subscription for \(scope.logDescription, privacy: .public) scope")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Created CloudKit database subscription for \(scope.logDescription) scope")
        }

        hasEnsuredDatabaseSubscriptions = true
    }

    private func ensurePrivateZoneSubscription(
        for zoneID: CKRecordZone.ID
    ) async throws {
        let subscriptionID = CloudKitSubscriptionIDs.privateZoneSubscriptionID(for: zoneID)
        guard !ensuredPrivateZoneSubscriptionIDs.contains(subscriptionID) else {
            return
        }

        if try await client.subscription(withID: subscriptionID, databaseScope: .private) == nil {
            let subscription = CKRecordZoneSubscription(
                zoneID: zoneID,
                subscriptionID: subscriptionID
            )
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            try await client.saveSubscription(subscription, databaseScope: .private)
            logger.info("Created CloudKit zone subscription for \(zoneID.zoneName, privacy: .public)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Created CloudKit zone subscription for \(zoneID.zoneName)")
        }

        ensuredPrivateZoneSubscriptionIDs.insert(subscriptionID)
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

    private func pullSharedDatabaseChanges(forceFullFetch: Bool = false) async throws {
        let anchor = forceFullFetch ? nil : try syncStateRepository.loadAnchor(
            databaseScope: "shared",
            zoneName: nil,
            ownerName: nil
        )
        let tokenDescription = anchor == nil ? "none — full fetch" : "incremental"
        logger.info("Checking shared database for changes (token: \(tokenDescription, privacy: .public))")
        AppLogger.shared.log(.info, category: "CloudKitSync", "Checking shared database for changes (token: \(tokenDescription))")

        var currentTokenData = anchor?.tokenData
        var latestTokenData: Data?

        repeat {
            let changes = try await client.databaseChanges(
                in: .shared,
                since: currentTokenData
            )
            logger.info("Shared database page: \(changes.modifiedZoneIDs.count, privacy: .public) modified zone(s), \(changes.deletedZoneIDs.count, privacy: .public) deleted zone(s), moreComing: \(changes.moreComing, privacy: .public)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Shared database page: \(changes.modifiedZoneIDs.count) modified zone(s), \(changes.deletedZoneIDs.count) deleted zone(s), moreComing: \(changes.moreComing)")

            for deletedZoneID in changes.deletedZoneIDs {
                logger.info("Shared zone deleted (access removed): \(deletedZoneID.zoneName, privacy: .public)")
                AppLogger.shared.log(.info, category: "CloudKitSync", "Shared zone deleted (access removed): \(deletedZoneID.zoneName)")
                let childID = childID(from: deletedZoneID.zoneName)
                try childRepository.purgeChildData(id: childID)
                pendingInvitesByChildID[childID] = []
            }

            for zoneID in changes.modifiedZoneIDs {
                logger.info("Shared zone modified (new/updated share): \(zoneID.zoneName, privacy: .public)")
                AppLogger.shared.log(.info, category: "CloudKitSync", "Shared zone modified (new/updated share): \(zoneID.zoneName)")
                let childID = childID(from: zoneID.zoneName)
                let context = CloudKitChildContext(
                    childID: childID,
                    zoneID: zoneID,
                    shareRecordName: nil,
                    databaseScope: .shared
                )
                try childRepository.saveCloudKitChildContext(context)
                try await pullZoneSnapshot(context: context)
            }

            latestTokenData = changes.tokenData
            currentTokenData = changes.moreComing ? changes.tokenData : nil
        } while currentTokenData != nil

        if let tokenData = latestTokenData {
            let newAnchor = SyncAnchor(
                databaseScope: .shared,
                zoneID: nil,
                tokenData: tokenData,
                lastSyncAt: .now
            )
            try syncStateRepository.saveAnchor(newAnchor)
        }
    }

    private func pullKnownChildZones(forceFullFetch: Bool = false) async throws {
        let children = try childRepository.loadAllChildren()
        logger.info("Found \(children.count, privacy: .public) child(ren) in local store")
        AppLogger.shared.log(.info, category: "CloudKitSync", "Found \(children.count) child(ren) in local store")

        for child in children {
            if let context = try childRepository.loadCloudKitChildContext(id: child.id) {
                logger.info(
                    "Child '\(child.name, privacy: .private)' — zone: \(context.zoneID.zoneName, privacy: .public), scope: \(context.databaseScope.logDescription, privacy: .public), isArchived: \(child.isArchived, privacy: .public)"
                )
                AppLogger.shared.log(.info, category: "CloudKitSync", "Child — zone: \(context.zoneID.zoneName), scope: \(context.databaseScope.logDescription), isArchived: \(child.isArchived)")
                if context.databaseScope == .private {
                    try await ensurePrivateZoneSubscription(for: context.zoneID)
                }
                if forceFullFetch {
                    logger.info("Child '\(child.name, privacy: .private)' — forcing manual full pull")
                    AppLogger.shared.log(.info, category: "CloudKitSync", "Child — forcing manual full pull")
                    try await pullZoneSnapshot(context: context, forceFullFetch: true)
                } else {
                    try await pullZoneSnapshot(context: context)
                }
                let memberships = try membershipRepository.loadMemberships(for: child.id)
                logger.info(
                    "Child '\(child.name, privacy: .private)' — \(memberships.count, privacy: .public) membership(s) in local store: \(memberships.map { "userID=\($0.userID) role=\($0.role) status=\($0.status)" }.joined(separator: ", "), privacy: .public)"
                )
                AppLogger.shared.log(.info, category: "CloudKitSync", "Child — \(memberships.count) membership(s) in local store")
                if try repairOrphanedMembershipIfNeeded(for: child, context: context) {
                    try await pushZoneSnapshot(for: child.id, context: context)
                }
                continue
            }

            logger.info("Child '\(child.name, privacy: .private)' — no CloudKit zone yet, creating private zone")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Child — no CloudKit zone yet, creating private zone")
            let context = try await ensureZoneContext(for: child.id, preferredScope: .private)
            try await pushPendingChanges(
                for: child.id,
                context: context,
                pendingRecords: try syncStateRepository.loadPendingRecords()
            )
        }
    }

    /// Detects and repairs the case where a child's membership was saved under
    /// a different local user identity (e.g. after a re-onboarding that generated
    /// a new UUID). Only acts on private zones where this device is the owner.
    /// Returns true if a repair was performed, so the caller can push the zone.
    @discardableResult
    private func repairOrphanedMembershipIfNeeded(
        for child: Child,
        context: CloudKitChildContext
    ) throws -> Bool {
        guard context.databaseScope == .private else { return false }
        guard let localUser = try userIdentityRepository.loadLocalUser() else { return false }

        let memberships = try membershipRepository.loadMemberships(for: child.id)
        guard !memberships.contains(where: { $0.userID == localUser.id }) else { return false }

        guard let orphaned = memberships.first(where: { $0.role == .owner }) else { return false }

        let repaired = Membership(
            id: orphaned.id,
            childID: orphaned.childID,
            userID: localUser.id,
            role: orphaned.role,
            status: orphaned.status,
            invitedAt: orphaned.invitedAt,
            acceptedAt: orphaned.acceptedAt
        )
        try membershipRepository.saveMembership(repaired)
        logger.warning(
            "Repaired orphaned membership for child '\(child.name, privacy: .private)': reassigned userID from \(orphaned.userID, privacy: .public) to \(localUser.id, privacy: .public)"
        )
        AppLogger.shared.log(.warning, category: "CloudKitSync", "Repaired orphaned membership: reassigned userID from \(orphaned.userID) to \(localUser.id)")
        return true
    }

    private func pushPendingChanges() async throws {
        let pendingRecords = try syncStateRepository.loadPendingRecords()

        if pendingRecords.isEmpty {
            logger.info("pushPendingChanges — nothing pending, skipping")
            AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — nothing pending, skipping")
        } else {
            let summary = pendingRecords.map { "\($0.recordType.rawValue):\($0.recordID)" }.joined(separator: ", ")
            logger.info("pushPendingChanges — \(pendingRecords.count, privacy: .public) pending record(s): \(summary, privacy: .public)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — \(pendingRecords.count) pending record(s): \(summary)")
        }

        // Clear any pending records whose childID no longer has a corresponding child in
        // the local store. These are orphaned (e.g. from a share that was left after
        // ensureMembershipForAcceptedShare ran) and can never be pushed.
        let knownChildIDs = Set(try childRepository.loadAllChildren().map(\.id))
        for record in pendingRecords where record.childID != nil && !knownChildIDs.contains(record.childID!) {
            logger.warning("pushPendingChanges — orphaned pending record \(record.recordType.rawValue):\(record.recordID, privacy: .public) has unknown childID \(record.childID!, privacy: .public), marking upToDate")
            AppLogger.shared.log(.warning, category: "CloudKitSync", "pushPendingChanges — orphaned pending record \(record.recordType.rawValue):\(record.recordID), marking upToDate")
            try syncStateRepository.updateSyncState(
                for: record,
                state: .upToDate,
                lastSyncedAt: nil,
                lastSyncErrorCode: nil
            )
        }

        let pendingUserIDs = Set(
            pendingRecords
                .filter { $0.recordType == .user }
                .map(\.recordID)
        )

        let children = try childRepository.loadAllChildren()
        for child in children {
            let memberships = try membershipRepository.loadMemberships(for: child.id)
            let childHasPending = pendingRecords.contains { $0.childID == child.id || $0.recordID == child.id }
            let childHasPendingUsers = memberships.contains { pendingUserIDs.contains($0.userID) }

            guard childHasPending || childHasPendingUsers else {
                logger.info("pushPendingChanges — '\(child.name, privacy: .private)': nothing pending, skipping")
                AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — child: nothing pending, skipping")
                continue
            }

            let context = try await ensureZoneContext(for: child.id, preferredScope: .private)
            logger.info("pushPendingChanges — '\(child.name, privacy: .private)': pushing pending records (scope: \(context.databaseScope.logDescription, privacy: .public))")
            AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — pushing pending records (scope: \(context.databaseScope.logDescription))")
            try await pushPendingChanges(
                for: child.id,
                context: context,
                pendingRecords: pendingRecords
            )
            logger.info("pushPendingChanges — '\(child.name, privacy: .private)': pending push complete")
            AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — pending push complete")
        }
    }

    private func pushPendingChanges(
        for childID: UUID,
        context: CloudKitChildContext,
        pendingRecords: [SyncRecordReference]
    ) async throws {
        let childPendingRecords = pendingRecords.filter { record in
            record.childID == childID || (record.recordType == .user && userRecordApplies(record, to: childID))
        }

        guard !childPendingRecords.isEmpty else {
            return
        }

        let outboundRecords = try buildOutboundRecords(
            for: childID,
            references: childPendingRecords,
            context: context
        )

        guard !outboundRecords.isEmpty else {
            return
        }

        let saveSummary = outboundRecords.map { $0.record.recordType }.joined(separator: ", ")
        logger.info("pushPendingChanges '\(childID.uuidString, privacy: .public)' — saving \(outboundRecords.count, privacy: .public) pending record(s) to \(context.databaseScope.logDescription, privacy: .public): [\(saveSummary, privacy: .public)]")
        AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — saving \(outboundRecords.count) pending record(s) to \(context.databaseScope.logDescription): [\(saveSummary)]")

        // CloudKit enforces a maximum of 400 records per CKModifyRecordsOperation.
        // Split into batches so large imports (e.g. from Huckleberry) don't fail.
        let cloudKitBatchLimit = 400
        var mergedSaveResults: [CKRecord.ID: Result<CKRecord, Error>] = [:]
        for batchStart in stride(from: 0, to: outboundRecords.count, by: cloudKitBatchLimit) {
            let batch = Array(outboundRecords[batchStart..<min(batchStart + cloudKitBatchLimit, outboundRecords.count)])
            if outboundRecords.count > cloudKitBatchLimit {
                logger.info("pushPendingChanges '\(childID.uuidString, privacy: .public)' — batch \(batchStart / cloudKitBatchLimit + 1, privacy: .public): \(batch.count, privacy: .public) record(s)")
                AppLogger.shared.log(.info, category: "CloudKitSync", "pushPendingChanges — batch \(batchStart / cloudKitBatchLimit + 1): \(batch.count) record(s)")
            }
            let batchResults = try await client.modifyRecords(
                saving: batch.map(\.record),
                deleting: [],
                databaseScope: context.databaseScope,
                savePolicy: .ifServerRecordUnchanged,
                atomically: false
            )
            mergedSaveResults.merge(batchResults.saveResults) { _, new in new }
        }

        for outboundRecord in outboundRecords {
            if let result = mergedSaveResults[outboundRecord.record.recordID] {
                switch result {
                case let .success(savedRecord):
                    try recordMetadataRepository.saveSystemFields(
                        CloudKitSystemFieldsCoder.encode(savedRecord),
                        for: savedRecord.recordID,
                        databaseScope: context.databaseScope
                    )
                    try syncStateRepository.updateSyncState(
                        for: outboundRecord.reference,
                        state: .upToDate,
                        lastSyncedAt: .now,
                        lastSyncErrorCode: nil
                    )
                case let .failure(error):
                    try syncStateRepository.updateSyncState(
                        for: outboundRecord.reference,
                        state: .pendingSync,
                        lastSyncedAt: nil,
                        lastSyncErrorCode: (error as NSError).localizedDescription
                    )
                    logger.error("pushPendingChanges failed for \(outboundRecord.record.recordType, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    AppLogger.shared.log(.error, category: "CloudKitSync", "pushPendingChanges failed for \(outboundRecord.record.recordType): \(error.localizedDescription)")
                }
            }
        }
    }

    private func pushZoneSnapshot(
        for childID: UUID,
        context: CloudKitChildContext
    ) async throws {
        guard let child = try childRepository.loadChild(id: childID) else {
            return
        }

        let memberships = try membershipRepository.loadMemberships(for: childID)
        let users = try userIdentityRepository.loadUsers(for: memberships.map(\.userID) + [child.createdBy])
        let events = try eventRepository.loadTimeline(
            for: childID,
            includingDeleted: true
        )

        let childRecord = CloudKitRecordMapper.childRecord(from: child, zoneID: context.zoneID)
        var recordsToSave: [CKRecord] = [childRecord]
        recordsToSave.append(contentsOf: users.map {
            CloudKitRecordMapper.userRecord(
                from: $0,
                zoneID: context.zoneID
            )
        })
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

            if let remoteRecord = existingRecords[record.recordID],
               isNonEventRecord(record),
               let remoteModifiedAt = remoteRecord.modificationDate,
               let localUpdatedAt = localUpdatedAt(for: record),
               remoteModifiedAt > localUpdatedAt {
                logger.debug("pushZoneSnapshot — skipping \(record.recordType, privacy: .public) \(record.recordID.recordName, privacy: .public): remote version is newer")
                AppLogger.shared.log(.debug, category: "CloudKitSync", "pushZoneSnapshot — skipping \(record.recordType) \(record.recordID.recordName): remote version is newer")
                continue
            }

            filteredSaves.append(record)
        }

        let savedTypes = filteredSaves.map(\.recordType).joined(separator: ", ")
        logger.info("pushZoneSnapshot '\(child.name, privacy: .private)' — saving \(filteredSaves.count, privacy: .public) record(s) to \(context.databaseScope.logDescription, privacy: .public): [\(savedTypes, privacy: .public)]")
        AppLogger.shared.log(.info, category: "CloudKitSync", "pushZoneSnapshot — saving \(filteredSaves.count) record(s) to \(context.databaseScope.logDescription): [\(savedTypes)]")
        let results = try await client.modifyRecords(
            saving: filteredSaves,
            deleting: [],
            databaseScope: context.databaseScope,
            savePolicy: .changedKeys,
            atomically: true
        )
        logger.info("pushZoneSnapshot '\(child.name, privacy: .private)' — modifyRecords succeeded")
        AppLogger.shared.log(.info, category: "CloudKitSync", "pushZoneSnapshot — modifyRecords succeeded")

        for record in filteredSaves {
            if case let .success(savedRecord)? = results.saveResults[record.recordID] {
                try recordMetadataRepository.saveSystemFields(
                    CloudKitSystemFieldsCoder.encode(savedRecord),
                    for: savedRecord.recordID,
                    databaseScope: context.databaseScope
                )
            }
        }

        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )

        for membership in memberships {
            logger.info("pushZoneSnapshot — marking membership upToDate: id=\(membership.id, privacy: .public) role=\(membership.role.rawValue, privacy: .public)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "pushZoneSnapshot — marking membership upToDate: id=\(membership.id) role=\(membership.role.rawValue)")
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

        let shareRecordID = context.shareRecordName.map {
            CKRecord.ID(recordName: $0, zoneID: context.zoneID)
        } ?? CloudKitRecordNames.zoneShareRecordID(zoneID: context.zoneID)
        if let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare {
            cachePendingInvites(for: childID, share: share)
        }
    }

    private func ensureRemoteChildRecordExists(
        for child: Child,
        context: CloudKitChildContext
    ) async throws {
        let childRecordID = CloudKitRecordNames.childRecordID(
            childID: child.id,
            zoneID: context.zoneID
        )

        let existingRecord = try await client.records(
            for: [childRecordID],
            databaseScope: context.databaseScope
        )[childRecordID]

        guard existingRecord == nil else {
            return
        }

        logger.info("prepareShare \(child.id, privacy: .public): child record missing remotely, uploading child record only")
        AppLogger.shared.log(.info, category: "CloudKitSync", "prepareShare \(child.id): child record missing remotely, uploading child record only")

        let childRecord = CloudKitRecordMapper.childRecord(
            from: child,
            zoneID: context.zoneID
        )
        let results = try await client.modifyRecords(
            saving: [childRecord],
            deleting: [],
            databaseScope: context.databaseScope,
            savePolicy: .changedKeys,
            atomically: true
        )

        if case let .success(savedRecord)? = results.saveResults[childRecord.recordID] {
            try recordMetadataRepository.saveSystemFields(
                CloudKitSystemFieldsCoder.encode(savedRecord),
                for: savedRecord.recordID,
                databaseScope: context.databaseScope
            )
        }

        try syncStateRepository.updateSyncState(
            for: SyncRecordReference(
                recordType: .child,
                recordID: child.id,
                childID: child.id
            ),
            state: .upToDate,
            lastSyncedAt: .now,
            lastSyncErrorCode: nil
        )
    }

    func forcePullAcceptedShare(
        zoneID: CKRecordZone.ID,
        shareRecordName: String
    ) async throws {
        let childID = childID(from: zoneID.zoneName)
        let context = CloudKitChildContext(
            childID: childID,
            zoneID: zoneID,
            shareRecordName: shareRecordName,
            databaseScope: .shared
        )
        try await pullZoneSnapshot(
            context: context,
            forceFullFetch: true
        )
    }

    private func pullZoneSnapshot(
        context: CloudKitChildContext,
        forceFullFetch: Bool = false
    ) async throws {
        let databaseScope = context.databaseScope == .shared ? "shared" : "private"
        // Clearing the anchor turns this into a complete zone snapshot fetch.
        let anchor = forceFullFetch ? nil : try syncStateRepository.loadAnchor(
            databaseScope: databaseScope,
            zoneName: context.zoneID.zoneName,
            ownerName: context.zoneID.ownerName
        )
        let changes: CloudKitRecordZoneChangeSet
        do {
            changes = try await client.recordZoneChanges(
                in: context.zoneID,
                databaseScope: context.databaseScope,
                since: anchor?.tokenData
            )
        } catch let error as CKError where error.code == .changeTokenExpired {
            logger.warning("pullZoneSnapshot \(context.zoneID.zoneName, privacy: .public): zone token expired, retrying with full fetch")
            AppLogger.shared.log(.warning, category: "CloudKitSync", "pullZoneSnapshot \(context.zoneID.zoneName): zone token expired, retrying with full fetch")
            changes = try await client.recordZoneChanges(
                in: context.zoneID,
                databaseScope: context.databaseScope,
                since: nil
            )
        }

        let recordTypes = changes.modifiedRecords.map(\.recordType)
        logger.info("pullZoneSnapshot \(context.zoneID.zoneName, privacy: .public) (\(databaseScope, privacy: .public)): \(changes.modifiedRecords.count, privacy: .public) modified, \(changes.deletions.count, privacy: .public) deleted — types: \(recordTypes.joined(separator: ", "), privacy: .public)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "pullZoneSnapshot \(context.zoneID.zoneName) (\(databaseScope)): \(changes.modifiedRecords.count) modified, \(changes.deletions.count) deleted — types: \(recordTypes.joined(separator: ", "))")

        for record in changes.modifiedRecords {
            try save(record: record, within: context)
        }

        for deletion in changes.deletions {
            try applyDeletion(deletion, within: context)
        }

        let updatedAnchor = SyncAnchor(
            databaseScope: context.databaseScope,
            zoneID: context.zoneID,
            tokenData: changes.tokenData,
            lastSyncAt: .now
        )
        try syncStateRepository.saveAnchor(updatedAnchor)

        let childID = context.childID
        let shareRecordID = context.shareRecordName.map {
            CKRecord.ID(recordName: $0, zoneID: context.zoneID)
        } ?? CloudKitRecordNames.zoneShareRecordID(zoneID: context.zoneID)
        if let share = try await client.records(
            for: [shareRecordID],
            databaseScope: context.databaseScope
        )[shareRecordID] as? CKShare {
            cachePendingInvites(for: childID, share: share)
        }
    }

    private func save(record: CKRecord, within context: CloudKitChildContext) throws {
        try recordMetadataRepository.saveSystemFields(
            CloudKitSystemFieldsCoder.encode(record),
            for: record.recordID,
            databaseScope: context.databaseScope
        )

        switch record.recordType {
        case CloudKitConfiguration.childRecordType:
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
        case CloudKitConfiguration.userRecordType:
            let user = try CloudKitRecordMapper.user(from: record)
            try userIdentityRepository.saveUser(user)
            try syncStateRepository.updateSyncState(
                for: SyncRecordReference(recordType: .user, recordID: user.id),
                state: .upToDate,
                lastSyncedAt: .now,
                lastSyncErrorCode: nil
            )
        case CloudKitConfiguration.membershipRecordType:
            let membership = CloudKitRecordMapper.membership(from: record)
            logger.info("Saving membership from CloudKit — role: \(membership.role.rawValue, privacy: .public), status: \(membership.status.rawValue, privacy: .public), childID: \(membership.childID, privacy: .public)")
            AppLogger.shared.log(.info, category: "CloudKitSync", "Saving membership from CloudKit — role: \(membership.role.rawValue), status: \(membership.status.rawValue), childID: \(membership.childID)")
            do {
                try membershipRepository.saveMembership(membership)
            } catch {
                logger.error("Failed to save membership (role: \(membership.role.rawValue, privacy: .public), status: \(membership.status.rawValue, privacy: .public)): \(error.localizedDescription, privacy: .public)")
                print("[BabyTracker] saveMembership FAILED role=\(membership.role.rawValue) status=\(membership.status.rawValue): \(error)")
                AppLogger.shared.log(.error, category: "CloudKitSync", "Failed to save membership (role: \(membership.role.rawValue), status: \(membership.status.rawValue)): \(error.localizedDescription)")
                throw error
            }
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
        case CloudKitConfiguration.breastFeedRecordType,
             CloudKitConfiguration.bottleFeedRecordType,
             CloudKitConfiguration.sleepRecordType,
             CloudKitConfiguration.nappyRecordType:
            let event = try CloudKitRecordMapper.event(from: record)
            if let localEvent = try eventRepository.loadEvent(id: event.id),
               LastWriteWinsResolver.prefersLocal(localEvent.metadata, over: event.metadata) {
                // If our local copy is newer, keep it. This avoids stale CloudKit pulls
                // overwriting edits that haven't been pushed yet.
                return
            }

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
            try trackRemoteCaregiverChange(for: event)
        default:
            return
        }
    }

    private func trackRemoteCaregiverChange(for event: BabyEvent) throws {
        guard shouldCollectRemoteCaregiverEvents else {
            return
        }

        let actorID = event.metadata.updatedBy
        guard actorID != currentLocalUserID else {
            return
        }

        let actorDisplayName = try displayName(for: actorID)
        remoteCaregiverEventChanges.append(
            RemoteCaregiverEventChange(
                actorDisplayName: actorDisplayName,
                event: event,
                isDeleted: event.metadata.isDeleted
            )
        )
    }

    private func displayName(for userID: UUID) throws -> String {
        if let cached = cachedUserDisplayNames[userID] {
            return cached
        }

        let user = try userIdentityRepository.loadUsers(for: [userID]).first
        let displayName = user?.displayName ?? "Another caregiver"
        cachedUserDisplayNames[userID] = displayName
        return displayName
    }

    private func applyDeletion(
        _ deletion: CloudKitRecordZoneDeletion,
        within context: CloudKitChildContext
    ) throws {
        try recordMetadataRepository.deleteSystemFields(
            for: deletion.recordID,
            databaseScope: context.databaseScope
        )

        if deletion.recordType == CloudKitConfiguration.childRecordType {
            let childID = childID(fromRecordName: deletion.recordID.recordName)
            try childRepository.purgeChildData(id: childID)
        }

        _ = context
    }

    private func ensureZoneContext(
        for childID: UUID,
        preferredScope: CKDatabase.Scope
    ) async throws -> CloudKitChildContext {
        if let existing = try childRepository.loadCloudKitChildContext(id: childID) {
            if existing.databaseScope == .private {
                try await ensurePrivateZoneSubscription(for: existing.zoneID)
            }
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

        if preferredScope == .private {
            try await ensurePrivateZoneSubscription(for: zoneID)
        }

        let context = CloudKitChildContext(
            childID: childID,
            zoneID: zoneID,
            shareRecordName: nil,
            databaseScope: preferredScope
        )
        try childRepository.saveCloudKitChildContext(context)
        return context
    }

    private func ensureMembershipForAcceptedShare(
        metadata: CKShare.Metadata
    ) async throws {
        guard let localUser = try userIdentityRepository.loadLocalUser() else {
            logger.warning("[4/5] ensureMembership — no local user found, skipping membership creation")
            AppLogger.shared.log(.warning, category: "CloudKitSync", "[4/5] ensureMembership — no local user found, skipping membership creation")
            return
        }

        let zoneID = metadata.share.recordID.zoneID
        let childID = childID(from: zoneID.zoneName)
        let existingMemberships = try membershipRepository.loadMemberships(for: childID)
        guard !existingMemberships.contains(where: { membership in
            membership.userID == localUser.id && membership.status == .active
        }) else {
            logger.info("[4/5] ensureMembership — active membership already exists, skipping")
            AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] ensureMembership — active membership already exists, skipping")
            return
        }

        let existingRoles = existingMemberships.map { "\($0.role.rawValue)/\($0.status.rawValue)" }.joined(separator: ", ")
        logger.info("[4/5] ensureMembership — existing memberships for child: [\(existingRoles.isEmpty ? "none" : existingRoles, privacy: .public)]")
        print("[BabyTracker][4/5] ensureMembership — existing memberships: [\(existingRoles.isEmpty ? "none" : existingRoles)]")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] ensureMembership — existing memberships: [\(existingRoles.isEmpty ? "none" : existingRoles)]")
        // The share recipient may not receive their membership record in the
        // first pull, so create the local caregiver membership explicitly.
        logger.info("[4/5] ensureMembership — creating caregiver membership for zone: \(zoneID.zoneName, privacy: .public)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] ensureMembership — creating caregiver membership for zone: \(zoneID.zoneName)")
        let membership = Membership(
            childID: childID,
            userID: localUser.id,
            role: .caregiver,
            status: .active,
            invitedAt: .now,
            acceptedAt: .now
        )

        try userIdentityRepository.saveUser(localUser)
        try membershipRepository.saveCloudKitMembership(membership)
        logger.info("[4/5] ensureMembership — saved local membership id=\(membership.id, privacy: .public), marking upToDate immediately (received from CloudKit, not a local write)")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] ensureMembership — saved local membership id=\(membership.id), marking upToDate immediately")
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
        let context = CloudKitChildContext(
            childID: childID,
            zoneID: zoneID,
            shareRecordName: metadata.share.recordID.recordName,
            databaseScope: .shared
        )
        try childRepository.saveCloudKitChildContext(context)
        logger.info("[4/5] ensureMembership — membership and CloudKit context saved")
        AppLogger.shared.log(.info, category: "CloudKitSync", "[4/5] ensureMembership — membership and CloudKit context saved")
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

    private func throwIfRefreshFailed(_ summary: SyncStatusSummary) throws {
        guard summary.state == .failed else {
            return
        }

        throw ShareAcceptanceError.refreshFailed(summary.lastErrorDescription)
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

    private func isNonEventRecord(_ record: CKRecord) -> Bool {
        switch record.recordType {
        case CloudKitConfiguration.childRecordType,
             CloudKitConfiguration.membershipRecordType,
             CloudKitConfiguration.userRecordType:
            return true
        default:
            return false
        }
    }

    /// Returns the best available local timestamp for comparing against the
    /// remote record's server-side modificationDate. Each record type uses the
    /// most recently updated domain field written by the record mapper.
    private func localUpdatedAt(for record: CKRecord) -> Date? {
        switch record.recordType {
        case CloudKitConfiguration.childRecordType,
             CloudKitConfiguration.userRecordType:
            return record["updatedAt"] as? Date ?? record["createdAt"] as? Date
        case CloudKitConfiguration.membershipRecordType:
            // acceptedAt is set when the caregiver accepts the share, making it
            // the most recent mutation timestamp for a membership record.
            let acceptedAt = record["acceptedAt"] as? Date
            let invitedAt = record["invitedAt"] as? Date
            if let acceptedAt, let invitedAt {
                return max(acceptedAt, invitedAt)
            }
            return acceptedAt ?? invitedAt
        default:
            return nil
        }
    }

    private func buildOutboundRecords(
        for childID: UUID,
        references: [SyncRecordReference],
        context: CloudKitChildContext
    ) throws -> [OutboundRecord] {
        var outboundRecords: [OutboundRecord] = []
        var seen = Set<SyncRecordReference>()

        for reference in references {
            guard !seen.contains(reference) else {
                continue
            }
            seen.insert(reference)

            guard let record = try outboundRecord(for: reference, childID: childID, context: context) else {
                continue
            }
            outboundRecords.append(record)
        }

        return outboundRecords
    }

    private func outboundRecord(
        for reference: SyncRecordReference,
        childID: UUID,
        context: CloudKitChildContext
    ) throws -> OutboundRecord? {
        let zoneID = context.zoneID

        switch reference.recordType {
        case .child:
            guard let child = try childRepository.loadChild(id: reference.recordID) else {
                return nil
            }
            return OutboundRecord(
                reference: SyncRecordReference(recordType: .child, recordID: child.id, childID: child.id),
                record: try hydratedRecord(
                    from: CloudKitRecordMapper.childRecord(from: child, zoneID: zoneID),
                    databaseScope: context.databaseScope
                )
            )
        case .user:
            guard let user = try userIdentityRepository.loadUsers(for: [reference.recordID]).first else {
                return nil
            }
            return OutboundRecord(
                reference: SyncRecordReference(recordType: .user, recordID: user.id),
                record: try hydratedRecord(
                    from: CloudKitRecordMapper.userRecord(from: user, zoneID: zoneID),
                    databaseScope: context.databaseScope
                )
            )
        case .membership:
            guard let membership = try membershipRepository.loadMemberships(for: childID)
                .first(where: { $0.id == reference.recordID }) else {
                return nil
            }
            return OutboundRecord(
                reference: SyncRecordReference(recordType: .membership, recordID: membership.id, childID: membership.childID),
                record: try hydratedRecord(
                    from: CloudKitRecordMapper.membershipRecord(from: membership, zoneID: zoneID),
                    databaseScope: context.databaseScope
                )
            )
        case .breastFeedEvent, .bottleFeedEvent, .sleepEvent, .nappyEvent:
            guard let event = try eventRepository.loadEvent(id: reference.recordID) else {
                return nil
            }
            return OutboundRecord(
                reference: SyncRecordReference(
                    recordType: recordType(for: event),
                    recordID: event.id,
                    childID: event.metadata.childID
                ),
                record: try hydratedRecord(
                    from: CloudKitRecordMapper.eventRecord(from: event, zoneID: zoneID),
                    databaseScope: context.databaseScope
                )
            )
        }
    }

    private func userRecordApplies(
        _ reference: SyncRecordReference,
        to childID: UUID
    ) -> Bool {
        guard reference.recordType == .user else {
            return false
        }

        let memberships = (try? membershipRepository.loadMemberships(for: childID)) ?? []
        return memberships.contains { $0.userID == reference.recordID }
    }

    private func hydratedRecord(
        from desiredRecord: CKRecord,
        databaseScope: CKDatabase.Scope
    ) throws -> CKRecord {
        guard let systemFields = try recordMetadataRepository.loadSystemFields(
            for: desiredRecord.recordID,
            databaseScope: databaseScope
        ) else {
            return desiredRecord
        }

        let hydratedRecord = try CloudKitSystemFieldsCoder.decodeRecord(from: systemFields)
        applyMutableValues(
            from: desiredRecord,
            to: hydratedRecord
        )
        return hydratedRecord
    }

    private func applyMutableValues(
        from source: CKRecord,
        to destination: CKRecord
    ) {
        for key in CloudKitRecordMapper.mutableFieldKeys(for: source.recordType) {
            destination[key] = source[key]
        }
        destination.parent = source.parent
    }
}

extension CloudKitSyncEngine {
    private struct OutboundRecord {
        let reference: SyncRecordReference
        let record: CKRecord
    }

    private enum RefreshReason {
        case launch
        case foreground
        case localWrite
        case manualFullRefresh
        case remoteNotification

        var logDescription: String {
            switch self {
            case .launch: return "launch"
            case .foreground: return "foreground"
            case .localWrite: return "localWrite"
            case .manualFullRefresh: return "manualFullRefresh"
            case .remoteNotification: return "remoteNotification"
            }
        }
    }
}

private extension CKAccountStatus {
    var logDescription: String {
        switch self {
        case .available: return "available"
        case .noAccount: return "no account"
        case .restricted: return "restricted"
        case .couldNotDetermine: return "could not determine"
        case .temporarilyUnavailable: return "temporarily unavailable"
        @unknown default: return "unknown"
        }
    }
}

private extension CKDatabase.Scope {
    var logDescription: String {
        switch self {
        case .private: return "private"
        case .shared: return "shared"
        case .public: return "public"
        @unknown default: return "unknown"
        }
    }
}
