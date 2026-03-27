import BabyTrackerDomain
import SwiftUI
import UIKit

public struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let editChildAction: () -> Void
    let shareChildAction: () -> Void
    let archiveAction: () -> Void
    let hardDeleteAction: () -> Void

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        editChildAction: @escaping () -> Void,
        shareChildAction: @escaping () -> Void,
        archiveAction: @escaping () -> Void,
        hardDeleteAction: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.editChildAction = editChildAction
        self.shareChildAction = shareChildAction
        self.archiveAction = archiveAction
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section {
                NavigationLink {
                    ChildProfileDetailsView(
                        model: model,
                        profile: profile,
                        editChildAction: editChildAction
                    )
                } label: {
                    childHeaderRow
                }
                .accessibilityIdentifier("profile-details-row")
            }

            Section("Sharing") {
                NavigationLink {
                    ChildProfileSharingView(
                        model: model,
                        profile: profile,
                        shareChildAction: shareChildAction
                    )
                } label: {
                    settingsRow(
                        title: "Sharing",
                        value: sharingSummary,
                        accessibilityIdentifier: "profile-sharing-row"
                    )
                }
            }

            if canSelectFromMultipleChildren || canCreateLocalChild {
                Section("Children") {
                    ForEach(model.activeChildren) { summary in
                        Button {
                            model.selectChild(id: summary.child.id)
                        } label: {
                            childSelectionRow(for: summary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("profile-select-child-\(summary.child.id.uuidString)")
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
                }
            }

            Section {
                NavigationLink {
                    ChildProfileSettingsView(
                        model: model,
                        profile: profile,
                        archiveAction: archiveAction,
                        hardDeleteAction: hardDeleteAction
                    )
                } label: {
                    settingsRow(
                        title: "Settings",
                        value: nil,
                        accessibilityIdentifier: "profile-settings-row"
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
                Text(profile.child.name)
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
        if let imageData = profile.child.imageData, let uiImage = UIImage(data: imageData) {
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
                Text(profile.child.name.prefix(1).uppercased())
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

            if summary.child.id == profile.child.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .accessibilityLabel("Selected child")
            }
        }
        .contentShape(Rectangle())
    }

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not set"
    }

    private var canCreateLocalChild: Bool {
        model.localUser != nil
    }

    private var canSelectFromMultipleChildren: Bool {
        model.activeChildren.count > 1
    }

    private var sharingSummary: String {
        let caregiverCount = 1 + profile.activeCaregivers.count
        let inviteCount = profile.pendingShareInvites.count
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
