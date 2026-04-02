import BabyTrackerDomain
import SwiftUI

public struct AppSettingsView: View {
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
            Section("iCloud & Backup") {
                NavigationLink {
                    ChildProfileSyncView(model: model, profile: profile)
                } label: {
                    settingsRow(
                        title: "Sync Status",
                        value: profile.cloudKitStatus.statusTitle,
                        accessibilityIdentifier: "app-settings-sync-row"
                    )
                }

            }

            Section("Data Tools") {
                NavigationLink {
                    ChildProfileExportView(model: model)
                } label: {
                    settingsRow(
                        title: "Export Data",
                        value: nil,
                        accessibilityIdentifier: "app-settings-export-row"
                    )
                }

                NavigationLink {
                    ChildProfileImportChoiceView(model: model)
                } label: {
                    settingsRow(
                        title: "Import Data",
                        value: nil,
                        accessibilityIdentifier: "app-settings-import-row"
                    )
                }
            }

            Section("Advanced") {
                NavigationLink {
                    LoggingView(appLogger: AppLogger.shared)
                } label: {
                    settingsRow(
                        title: "Logs",
                        value: nil,
                        accessibilityIdentifier: "app-settings-logs-row"
                    )
                }
            }

            Section("Account Reset") {
                NavigationLink {
                    NukeAllDataView(nukeAction: { model.nukeAllData() })
                } label: {
                    settingsRow(
                        title: "Erase Everything",
                        value: nil,
                        accessibilityIdentifier: "nuke-all-data-row",
                        titleColor: .red
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func settingsRow(
        title: String,
        value: String?,
        accessibilityIdentifier: String,
        titleColor: Color = .primary
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundStyle(titleColor)

            Spacer()

            if let value {
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            AppSettingsView(model: model, profile: profile)
        }
    }
}
