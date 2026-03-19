import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

struct CloudKitStatusViewStateTests {
    @Test
    func upToDateSummaryShowsBackedUpState() {
        let summary = SyncStatusSummary(
            state: .upToDate,
            pendingRecordCount: 0,
            lastSyncAt: Date(timeIntervalSince1970: 1_000),
            lastErrorDescription: nil
        )

        let viewState = CloudKitStatusViewState(summary: summary)

        #expect(viewState.statusTitle == "Up to date")
        #expect(viewState.backupTitle == "Backed up to iCloud")
        #expect(viewState.pendingChangesTitle == nil)
        #expect(viewState.detailMessage == nil)
    }

    @Test
    func pendingSummaryShowsPendingChangeCount() {
        let summary = SyncStatusSummary(
            state: .pendingSync,
            pendingRecordCount: 2,
            lastSyncAt: nil,
            lastErrorDescription: nil
        )

        let viewState = CloudKitStatusViewState(summary: summary)

        #expect(viewState.statusTitle == "Waiting to sync")
        #expect(viewState.backupTitle == "Not backed up yet")
        #expect(viewState.pendingChangesTitle == "2 changes")
        #expect(viewState.detailMessage == "2 changes are waiting to sync.")
    }

    @Test
    func failedSummaryPreservesLastBackupAndErrorDetail() {
        let summary = SyncStatusSummary(
            state: .failed,
            pendingRecordCount: 0,
            lastSyncAt: Date(timeIntervalSince1970: 2_000),
            lastErrorDescription: "Sync unavailable. Sign in to iCloud."
        )

        let viewState = CloudKitStatusViewState(summary: summary)

        #expect(viewState.statusTitle == "Sync unavailable")
        #expect(viewState.backupTitle == "Last backup available")
        #expect(viewState.detailMessage == "Sync unavailable. Sign in to iCloud.")
    }
}
