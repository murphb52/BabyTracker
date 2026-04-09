import BabyTrackerDomain
import SwiftUI

public struct ChildProfileSyncView: View {
    let model: AppModel
    let viewModel: ChildProfileViewModel

    public init(
        model: AppModel,
        viewModel: ChildProfileViewModel
    ) {
        self.model = model
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            if let bannerTitle = viewModel.cloudKitStatus.syncSettingsBannerTitle,
               let bannerMessage = viewModel.cloudKitStatus.syncSettingsBannerMessage {
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
                    Text(viewModel.cloudKitStatus.statusTitle)
                        .foregroundStyle(syncStatusColor(for: viewModel.cloudKitStatus))
                }

                LabeledContent("Backup") {
                    Text(viewModel.cloudKitStatus.backupTitle)
                }

                if let lastSyncAt = viewModel.cloudKitStatus.lastSyncAt {
                    TimelineView(.everyMinute) { context in
                        LabeledContent("Last Synced") {
                            Text(RelativeSyncTextFormatter.lastSyncedText(for: lastSyncAt, relativeTo: context.date))
                        }
                    }
                }

                if !viewModel.pendingChanges.isEmpty {
                    LabeledContent("Pending Changes") {
                        Text("\(viewModel.pendingChanges.reduce(0) { $0 + $1.count })")
                    }
                } else if let pendingChangesTitle = viewModel.cloudKitStatus.pendingChangesTitle {
                    LabeledContent("Pending Changes") {
                        Text(pendingChangesTitle)
                    }
                }
            }

            if !viewModel.pendingChanges.isEmpty {
                Section("Current Child Pending Changes") {
                    ForEach(viewModel.pendingChanges, id: \.label) { item in
                        LabeledContent {
                            Text("\(item.count)")
                                .foregroundStyle(.secondary)
                        } label: {
                            Label(item.label, systemImage: item.icon)
                        }
                    }
                }
            }

            if let detailMessage = viewModel.cloudKitStatus.detailMessage {
                Section("Details") {
                    Text(detailMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let marker = viewModel.latestEventSyncMarker {
                Section("Advanced Diagnostics") {
                    LabeledContent("Visible Events") {
                        Text("\(viewModel.totalEventCount)")
                    }

                    LabeledContent("Latest Event Type") {
                        Text(BabyEventPresentation.title(for: marker.kind))
                    }

                    LabeledContent("Latest Updated") {
                        Text(marker.updatedAt, format: .dateTime.month(.abbreviated).day().hour().minute().second())
                    }

                    LabeledContent("Latest Occurred") {
                        Text(marker.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute().second())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest Event ID")
                            .font(.subheadline.weight(.medium))

                        Text(marker.id.uuidString)
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
        case .upToDate: .green
        case .syncing: .blue
        case .pendingSync: .orange
        case .failed: .red
        }
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildProfileSyncView(
            model: model,
            viewModel: ChildProfileViewModel(appModel: model)
        )
    }
}
