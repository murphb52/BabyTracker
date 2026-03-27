import SwiftUI
import BabyTrackerDomain

public struct ChildProfileSettingsView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let archiveAction: () -> Void
    let hardDeleteAction: () -> Void

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        archiveAction: @escaping () -> Void,
        hardDeleteAction: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.archiveAction = archiveAction
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section {
                NavigationLink {
                    ChildProfileSyncView(model: model, profile: profile)
                } label: {
                    Text("iCloud Sync")
                }
                .accessibilityIdentifier("profile-sync-row")

                NavigationLink {
                    LoggingView(appLogger: AppLogger.shared)
                } label: {
                    Text("Logs")
                }
                .accessibilityIdentifier("profile-logs-row")

                NavigationLink {
                    ChildProfileExportView(model: model)
                } label: {
                    Text("Export Data")
                }
                .accessibilityIdentifier("profile-export-row")

                NavigationLink {
                    ChildProfileImportChoiceView(model: model)
                } label: {
                    Text("Import Data")
                }
                .accessibilityIdentifier("profile-import-row")
            }

            if profile.canArchiveChild {
                Section {
                    NavigationLink {
                        ChildProfileArchiveView(
                            profile: profile,
                            archiveAction: archiveAction
                        )
                    } label: {
                        Text("Archive Child")
                            .foregroundStyle(.red)
                    }
                    .accessibilityIdentifier("profile-archive-row")
                }
            }

            Section {
                NavigationLink {
                    ChildProfileHardDeleteView(hardDeleteAction: hardDeleteAction)
                } label: {
                    Text("Hard Delete")
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("profile-hard-delete-row")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
