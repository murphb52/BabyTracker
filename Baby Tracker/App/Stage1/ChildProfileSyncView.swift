import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileSyncView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    var body: some View {
        List {
            Section("Status") {
                LabeledContent("Sync") {
                    Text(profile.cloudKitStatus.statusTitle)
                        .foregroundStyle(syncStatusColor(for: profile.cloudKitStatus))
                }

                LabeledContent("Backup") {
                    Text(profile.cloudKitStatus.backupTitle)
                }

                if let lastSyncAt = profile.cloudKitStatus.lastSyncAt {
                    LabeledContent("Last Sync") {
                        Text(lastSyncAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    }
                }

                if let pendingChangesTitle = profile.cloudKitStatus.pendingChangesTitle {
                    LabeledContent("Pending Changes") {
                        Text(pendingChangesTitle)
                    }
                }
            }

            if let detailMessage = profile.cloudKitStatus.detailMessage {
                Section("Details") {
                    Text(detailMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Refresh Sync Status") {
                    model.refreshSyncStatus()
                }
                .accessibilityIdentifier("refresh-sync-status-button")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private func syncStatusColor(for state: CloudKitStatusViewState) -> Color {
        switch state.state {
        case .upToDate:
            .green
        case .syncing:
            .blue
        case .pendingSync:
            .orange
        case .failed:
            .red
        }
    }
}
