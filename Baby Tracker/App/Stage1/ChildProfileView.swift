import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let archiveAction: () -> Void

    var body: some View {
        List {
            Section("Profile") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.child.name)
                        .font(.title3.weight(.semibold))
                        .accessibilityIdentifier("child-profile-name")

                    Text(birthDateText)
                        .foregroundStyle(.secondary)

                    Text("Signed in as \(profile.localUser.displayName)")
                        .foregroundStyle(.secondary)
                }

                if profile.canSwitchChildren {
                    Button("Switch Child", systemImage: "arrow.left.arrow.right") {
                        model.showChildPicker()
                    }
                    .accessibilityIdentifier("switch-child-button")
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

            Section("iCloud Sync") {
                LabeledContent("Status") {
                    Text(profile.cloudKitStatus.statusTitle)
                        .foregroundStyle(syncStatusColor(for: profile.cloudKitStatus))
                }

                LabeledContent("Backup") {
                    Text(profile.cloudKitStatus.backupTitle)
                }

                if let lastSyncAt = profile.cloudKitStatus.lastSyncAt {
                    LabeledContent("Last Sync") {
                        Text(lastSyncAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    }
                }

                if let pendingChangesTitle = profile.cloudKitStatus.pendingChangesTitle {
                    LabeledContent("Pending Changes") {
                        Text(pendingChangesTitle)
                    }
                }

                if let detailMessage = profile.cloudKitStatus.detailMessage {
                    Text(detailMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if profile.canArchiveChild {
                Section {
                    Button("Archive Child", role: .destructive, action: archiveAction)
                    .accessibilityIdentifier("archive-child-button")
                }
            }
        }
    }

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            "Birth date: \(birthDate.formatted(date: .abbreviated, time: .omitted))"
        } else {
            "Birth date not added yet"
        }
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
                HStack {
                    if showsRemoval {
                        Button("Remove", role: .destructive) {
                            model.removeCaregiver(membershipID: caregiver.membership.id)
                        }
                        .accessibilityIdentifier("remove-caregiver-\(caregiver.membership.id.uuidString)")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }

    private func syncStatusColor(for state: CloudKitStatusViewState) -> Color {
        switch state.state {
        case .upToDate:
            .green
        case .syncing:
            .blue
        case .pendingSync:
            .orange
        case .failed:
            .red
        }
    }
}
