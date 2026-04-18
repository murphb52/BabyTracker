import BabyTrackerDomain
import SwiftUI

public struct AppSettingsView: View {
    let model: AppModel
    let viewModel: ChildProfileViewModel
    @State private var demoOnboardingModel: AppModel?

    public init(
        model: AppModel,
        viewModel: ChildProfileViewModel
    ) {
        self.model = model
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section("iCloud & Backup") {
                NavigationLink {
                    ChildProfileSyncView(model: model, viewModel: viewModel)
                } label: {
                    settingsRow(
                        title: "Sync Status",
                        value: viewModel.cloudKitStatus.statusTitle,
                        accessibilityIdentifier: "app-settings-sync-row"
                    )
                }
            }

            Section("Data Tools") {
                NavigationLink {
                    ChildProfileExportView(appModel: model)
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
                    AccentColorPickerView()
                } label: {
                    settingsRow(
                        title: "Accent Colour",
                        value: nil,
                        accessibilityIdentifier: "app-settings-accent-color-row"
                    )
                }

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

            Section("Help") {
                Button {
                    model.showOnboarding()
                } label: {
                    settingsRow(
                        title: "Start Onboarding",
                        value: nil,
                        accessibilityIdentifier: "app-settings-onboarding-row"
                    )
                }
                .foregroundStyle(.primary)

                Button {
                    demoOnboardingModel = AppModel.makeInMemoryDemoModel()
                } label: {
                    settingsRow(
                        title: "Preview New Onboarding",
                        value: nil,
                        accessibilityIdentifier: "app-settings-preview-onboarding-row"
                    )
                }
                .foregroundStyle(.primary)
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

            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("App Version")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(appVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("app-version-label")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: Binding(
            get: { demoOnboardingModel?.isInteractiveOnboardingActive ?? false },
            set: { isActive in if !isActive { demoOnboardingModel = nil } }
        )) {
            if let dm = demoOnboardingModel {
                InteractiveOnboardingView(model: dm)
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
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
        AppSettingsView(
            model: model,
            viewModel: ChildProfileViewModel(appModel: model)
        )
    }
}
