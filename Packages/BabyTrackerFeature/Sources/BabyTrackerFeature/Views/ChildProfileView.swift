import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import SwiftUI
import UIKit

public struct ChildProfileView: View {
    let model: AppModel
    let viewModel: ChildProfileViewModel
    let editChildAction: () -> Void
    let shareChildAction: () -> Void
    let archiveAction: () -> Void
    let hardDeleteAction: () -> Void

    public init(
        model: AppModel,
        viewModel: ChildProfileViewModel,
        editChildAction: @escaping () -> Void,
        shareChildAction: @escaping () -> Void,
        archiveAction: @escaping () -> Void,
        hardDeleteAction: @escaping () -> Void
    ) {
        self.model = model
        self.viewModel = viewModel
        self.editChildAction = editChildAction
        self.shareChildAction = shareChildAction
        self.archiveAction = archiveAction
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section("This Child") {
                NavigationLink {
                    ChildProfileDetailsView(
                        viewModel: viewModel,
                        editChildAction: editChildAction
                    )
                } label: {
                    childHeaderRow
                }
                .accessibilityIdentifier("profile-details-row")

                Picker("Bottle Volume Unit", selection: volumeUnitBinding) {
                    ForEach(FeedVolumeUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.shortTitle).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("child-feed-volume-unit-picker")

                Toggle(
                    "Live Activities",
                    isOn: Binding(
                        get: { model.isLiveActivityEnabled },
                        set: { model.setLiveActivitiesEnabled($0) }
                    )
                )
                .accessibilityIdentifier("live-activities-toggle")

                if showsManageChild {
                    NavigationLink {
                        ChildProfileManageView(
                            model: model,
                            viewModel: viewModel,
                            archiveAction: archiveAction,
                            hardDeleteAction: hardDeleteAction
                        )
                    } label: {
                        settingsRow(
                            title: "Manage Child",
                            value: nil,
                            accessibilityIdentifier: "profile-manage-child-row"
                        )
                    }
                }
            }

            Section("Family & Sharing") {
                NavigationLink {
                    ChildProfileSharingView(
                        model: model,
                        viewModel: viewModel,
                        shareChildAction: shareChildAction
                    )
                } label: {
                    settingsRow(
                        title: "Sharing & Caregivers",
                        value: sharingSummary,
                        accessibilityIdentifier: "profile-sharing-row"
                    )
                }

                LabeledContent("Signed In As") {
                    Text(viewModel.localUser?.displayName ?? "")
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("profile-signed-in-as-row")
            }

            if canSelectFromMultipleChildren || canCreateLocalChild || hasArchivedChildren {
                Section("Profiles") {
                    if canSelectFromMultipleChildren {
                        ForEach(model.activeChildren) { summary in
                            Button {
                                model.selectChild(id: summary.child.id)
                            } label: {
                                childSelectionRow(for: summary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("profile-select-child-\(summary.child.id.uuidString)")
                        }
                    }

                    if canCreateLocalChild {
                        NavigationLink {
                            ChildCreationView(model: model)
                        } label: {
                            settingsRow(
                                title: "Add Child",
                                value: nil,
                                accessibilityIdentifier: "profile-add-child-row"
                            )
                        }
                    }

                    if hasArchivedChildren {
                        NavigationLink {
                            ArchivedProfilesView(model: model)
                        } label: {
                            settingsRow(
                                title: "Archived Profiles",
                                value: "\(model.archivedChildren.count)",
                                accessibilityIdentifier: "profile-archived-profiles-row"
                            )
                        }
                    }
                }
            }

            Section("Support") {
                NavigationLink {
                    HelpFAQView()
                } label: {
                    settingsRow(
                        title: "Help & FAQ",
                        value: nil,
                        accessibilityIdentifier: "profile-help-faq-row"
                    )
                }

                NavigationLink {
                    AppSettingsView(
                        model: model,
                        viewModel: viewModel
                    )
                } label: {
                    settingsRow(
                        title: "App Settings",
                        value: nil,
                        accessibilityIdentifier: "profile-app-settings-row"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
    }

    @ViewBuilder
    private var childHeaderRow: some View {
        HStack(spacing: 16) {
            avatarView

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.childName)
                    .font(.headline)

                Text(birthDateText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imageData = viewModel.child?.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Text(viewModel.childName.prefix(1).uppercased())
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    @ViewBuilder
    private func childSelectionRow(for summary: ChildSummary) -> some View {
        HStack(spacing: 12) {
            Text(summary.child.name)
                .foregroundStyle(.primary)

            Spacer()

            Text(summary.membership.role == .owner ? "Owner" : "Caregiver")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if summary.child.id == viewModel.child?.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Selected child")
            }
        }
        .contentShape(Rectangle())
    }

    private var volumeUnitBinding: Binding<FeedVolumeUnit> {
        Binding(
            get: { viewModel.child?.preferredFeedVolumeUnit ?? .milliliters },
            set: { selectedUnit in
                model.updateCurrentChild(
                    name: viewModel.childName,
                    birthDate: viewModel.child?.birthDate,
                    imageData: viewModel.child?.imageData,
                    preferredFeedVolumeUnit: selectedUnit
                )
            }
        )
    }

    private var birthDateText: String {
        if let birthDate = viewModel.child?.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not set"
    }

    private var canCreateLocalChild: Bool {
        model.localUser != nil
    }

    private var hasArchivedChildren: Bool {
        !model.archivedChildren.isEmpty
    }

    private var canSelectFromMultipleChildren: Bool {
        model.activeChildren.count > 1
    }

    private var showsManageChild: Bool {
        viewModel.canArchiveChild || viewModel.canLeaveShare || viewModel.canHardDelete
    }

    private var sharingSummary: String {
        let caregiverCount = 1 + viewModel.activeCaregivers.count
        let inviteCount = viewModel.pendingShareInvites.count
        let caregiverText = caregiverCount == 1 ? "1 person" : "\(caregiverCount) people"

        guard inviteCount > 0 else {
            return caregiverText
        }

        let inviteText = inviteCount == 1 ? "1 invite" : "\(inviteCount) invites"
        return "\(caregiverText), \(inviteText)"
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
        ChildProfileView(
            model: model,
            viewModel: ChildProfileViewModel(appModel: model),
            editChildAction: {},
            shareChildAction: {},
            archiveAction: {},
            hardDeleteAction: {}
        )
    }
}
