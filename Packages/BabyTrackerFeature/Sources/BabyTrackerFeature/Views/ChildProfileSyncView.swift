import BabyTrackerDomain
import SwiftUI

public struct ChildProfileSyncView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    public init(
        model: AppModel,
        profile: ChildProfileScreenState
    ) {
        self.model = model
        self.profile = profile
    }

    public var body: some View {
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

            if !profile.pendingChanges.isEmpty {
                Section("Pending Changes") {
                    ForEach(profile.pendingChanges, id: \.label) { item in
                        LabeledContent {
                            Text("\(item.count)")
                                .foregroundStyle(.secondary)
                        } label: {
                            Label(item.label, systemImage: item.icon)
                        }
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
                    Task { await model.refreshSyncStatus() }
                }
                .accessibilityIdentifier("refresh-sync-status-button")

                Button("Complete Refresh") {
                    Task { await model.forceFullSyncRefresh() }
                }
                .accessibilityIdentifier("complete-refresh-sync-button")
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .task { await model.refreshSyncStatus() }
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
