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

            Section("Live Activities") {
                Toggle(
                    "Enable Live Activities",
                    isOn: Binding(
                        get: { model.isLiveActivityEnabled },
                        set: { model.setLiveActivitiesEnabled($0) }
                    )
                )
                .accessibilityIdentifier("live-activities-toggle")

                Text("This setting controls the app's Live Activities on the Lock Screen and Dynamic Island. iOS does not currently expose reliable per-size controls here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

            if profile.canHardDelete {
                Section {
                    NavigationLink {
                        ChildProfileHardDeleteView(
                            childName: profile.child.name,
                            hardDeleteAction: hardDeleteAction
                        )
                    } label: {
                        Text("Hard Delete")
                            .foregroundStyle(.red)
                    }
                    .accessibilityIdentifier("profile-hard-delete-row")
                }
            }

            Section {
                NavigationLink {
                    NukeAllDataView(nukeAction: { model.nukeAllData() })
                } label: {
                    Text("Erase Everything")
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("nuke-all-data-row")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
