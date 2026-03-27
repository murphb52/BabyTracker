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
                    Label(sharingSummary, systemImage: "person.2")
                }
                .accessibilityIdentifier("profile-sharing-row")
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
                    Text("Settings")
                }
                .accessibilityIdentifier("profile-settings-row")
            }

            if profile.canSwitchChildren {
                Section {
                    Button {
                        model.showChildPicker()
                    } label: {
                        Text("Switch Child")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("switch-child-button")
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

    private var birthDateText: String {
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
}
