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
            if let bannerTitle = profile.cloudKitStatus.syncSettingsBannerTitle,
               let bannerMessage = profile.cloudKitStatus.syncSettingsBannerMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(bannerTitle, systemImage: "icloud.slash")
                            .font(.headline)

                        Text(bannerMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("icloud-sync-unavailable-banner")
                }
            }

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

                if !profile.pendingChanges.isEmpty {
                    LabeledContent("Pending Changes") {
                        Text("\(profile.pendingChanges.reduce(0) { $0 + $1.count })")
                    }
                } else if let pendingChangesTitle = profile.cloudKitStatus.pendingChangesTitle {
                    LabeledContent("Pending Changes") {
                        Text(pendingChangesTitle)
                    }
                }
            }

            if !profile.pendingChanges.isEmpty {
                Section("Current Child Pending Changes") {
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

            if let latestEventSyncMarker = profile.latestEventSyncMarker {
                Section("Advanced Diagnostics") {
                    LabeledContent("Visible Events") {
                        Text("\(profile.totalEventCount)")
                    }

                    LabeledContent("Latest Event Type") {
                        Text(BabyEventPresentation.title(for: latestEventSyncMarker.kind))
                    }

                    LabeledContent("Latest Updated") {
                        Text(latestEventSyncMarker.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute().second())
                    }

                    LabeledContent("Latest Occurred") {
                        Text(latestEventSyncMarker.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute().second())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest Event ID")
                            .font(.subheadline.weight(.medium))

                        Text(latestEventSyncMarker.id.uuidString)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }

            Section("Actions") {
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

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildProfileSyncView(model: model, profile: profile)
        }
    }
}
