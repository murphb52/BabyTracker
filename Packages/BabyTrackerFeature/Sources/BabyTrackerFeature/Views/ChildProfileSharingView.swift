import BabyTrackerDomain
import SwiftUI

public struct ChildProfileSharingView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let shareChildAction: () -> Void

    @State private var showingLeaveConfirmation = false

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        shareChildAction: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.shareChildAction = shareChildAction
    }

    public var body: some View {
        List {
            if profile.canManageSharing {
                Section {
                    Button {
                        shareChildAction()
                    } label: {
                        Label("Share Child", systemImage: "person.crop.circle.badge.plus")
                    }
                    .disabled(!profile.canShareChild)
                    .accessibilityIdentifier("share-child-button")

                    if let shareUnavailableMessage {
                        Text(shareUnavailableMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("share-child-unavailable-message")
                    }
                }
            }

            if let owner = profile.owner {
                Section("Owner") {
                    caregiverRow(for: owner, showsRemoval: false)
                }
            }

            if !profile.activeCaregivers.isEmpty {
                Section("Active Caregivers") {
                    ForEach(profile.activeCaregivers) { caregiver in
                        caregiverRow(
                            for: caregiver,
                            showsRemoval: profile.canManageSharing
                        )
                    }
                }
            }

            if !profile.pendingShareInvites.isEmpty {
                Section("Pending Invitations") {
                    ForEach(profile.pendingShareInvites) { invite in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invite.displayName)
                                .font(.headline)

                            Text(invite.statusLabel)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !profile.removedCaregivers.isEmpty {
                Section("Removed Caregivers") {
                    ForEach(profile.removedCaregivers) { caregiver in
                        caregiverRow(for: caregiver, showsRemoval: false)
                    }
                }
            }
            if profile.canLeaveShare {
                Section {
                    Button("Leave Profile", role: .destructive) {
                        showingLeaveConfirmation = true
                    }
                    .accessibilityIdentifier("leave-share-button")
                }
            }
        }
        .navigationTitle("Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .confirmationDialog(
            "Leave \(profile.child.name)?",
            isPresented: $showingLeaveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Leave Profile", role: .destructive) {
                model.leaveChildShare()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All data for \(profile.child.name) will be removed from this device. You can rejoin if the owner invites you again.")
        }
    }

    private var shareUnavailableMessage: String? {
        guard !profile.canShareChild else {
            return nil
        }

        if profile.cloudKitStatus.isAccountUnavailable {
            return "Sharing is unavailable until iCloud backup is available. Check the iCloud Sync screen for details."
        }

        if let detailMessage = profile.cloudKitStatus.detailMessage {
            return "Sharing is unavailable right now. \(detailMessage)"
        }

        return "Sharing is unavailable until iCloud sync is working on this device."
    }

    @ViewBuilder
    private func caregiverRow(
        for caregiver: CaregiverMembershipViewState,
        showsRemoval: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caregiver.displayName)
                    .font(.headline)

                Text(caregiver.statusLabel)
                    .font(.subheadline.weight(.medium))

                Text(caregiver.secondaryLabel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if showsRemoval {
                Button("Remove", role: .destructive) {
                    model.removeCaregiver(membershipID: caregiver.membership.id)
                }
                .accessibilityIdentifier("remove-caregiver-\(caregiver.membership.id.uuidString)")
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}
