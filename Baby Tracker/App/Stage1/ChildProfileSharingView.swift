import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileSharingView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let shareChildAction: () -> Void

    var body: some View {
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
                }
            }

            Section("Owner") {
                caregiverRow(for: profile.owner, showsRemoval: false)
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
        }
        .navigationTitle("Sharing")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
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
