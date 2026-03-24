import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let editChildAction: () -> Void
    let shareChildAction: () -> Void
    let archiveAction: () -> Void

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ChildProfileDetailsView(
                        profile: profile,
                        editChildAction: editChildAction
                    )
                } label: {
                    settingsRow(
                        title: "Details",
                        value: detailsSummary,
                        accessibilityIdentifier: "profile-details-row"
                    )
                }

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

                NavigationLink {
                    ChildProfileSyncView(
                        model: model,
                        profile: profile
                    )
                } label: {
                    settingsRow(
                        title: "iCloud Sync",
                        value: profile.cloudKitStatus.statusTitle,
                        accessibilityIdentifier: "profile-sync-row"
                    )
                }

                if profile.canSwitchChildren {
                    Button {
                        model.showChildPicker()
                    } label: {
                        settingsRow(
                            title: "Switch Child",
                            value: nil,
                            accessibilityIdentifier: "switch-child-button"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if profile.canArchiveChild {
                Section {
                    NavigationLink {
                        ChildProfileArchiveView(
                            profile: profile,
                            archiveAction: archiveAction
                        )
                    } label: {
                        settingsRow(
                            title: "Archive Child",
                            value: nil,
                            accessibilityIdentifier: "profile-archive-row",
                            titleColor: .red
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var detailsSummary: String {
        if let birthDate = profile.child.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not set"
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
