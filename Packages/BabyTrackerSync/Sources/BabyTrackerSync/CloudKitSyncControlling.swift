import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation

@MainActor
public protocol CloudKitSyncControlling: AnyObject {
    var statusSummary: SyncStatusSummary { get }

    func prepareForLaunch() async -> SyncStatusSummary
    func refreshAfterLocalWrite() async -> SyncStatusSummary
    func refreshForeground() async -> SyncStatusSummary
    func refreshAfterRemoteNotification() async -> SyncStatusSummary
    func pendingInvites(for childID: UUID) -> [CloudKitPendingInvite]
    func consumeRemoteCaregiverEventChanges() -> [RemoteCaregiverEventChange]
    func prepareShare(for childID: UUID) async throws -> CloudKitSharePresentation
    func removeParticipant(membership: Membership) async throws
    func loadPendingChangeCounts() throws -> [SyncRecordType: Int]
    func leaveShare(childID: UUID) async throws
    func hardDeleteAllCloudData() async throws
}

extension CloudKitSyncEngine: CloudKitSyncControlling {}
