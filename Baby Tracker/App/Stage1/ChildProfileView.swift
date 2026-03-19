import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: Stage1AppModel
    let profile: ChildProfileScreenState

    @State private var showingEditChildSheet = false
    @State private var showingInviteCaregiverSheet = false
    @State private var showingArchiveConfirmation = false

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
                caregiverRow(for: profile.owner, showsActivation: false, showsRemoval: false)
            }

            if !profile.activeCaregivers.isEmpty {
                Section("Active Caregivers") {
                    ForEach(profile.activeCaregivers) { caregiver in
                        caregiverRow(
                            for: caregiver,
                            showsActivation: false,
                            showsRemoval: profile.canManageSharing
                        )
                    }
                }
            }

            if !profile.invitedCaregivers.isEmpty {
                Section("Invited Caregivers") {
                    Text("Activation is temporary Stage 1 scaffolding until CloudKit sharing is added.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(profile.invitedCaregivers) { caregiver in
                        caregiverRow(
                            for: caregiver,
                            showsActivation: profile.canManageSharing,
                            showsRemoval: profile.canManageSharing
                        )
                    }
                }
            }

            if !profile.removedCaregivers.isEmpty {
                Section("Removed Caregivers") {
                    ForEach(profile.removedCaregivers) { caregiver in
                        caregiverRow(for: caregiver, showsActivation: false, showsRemoval: false)
                    }
                }
            }

            if profile.canArchiveChild {
                Section {
                    Button("Archive Child", role: .destructive) {
                        showingArchiveConfirmation = true
                    }
                    .accessibilityIdentifier("archive-child-button")
                }
            }
        }
        .sheet(isPresented: $showingEditChildSheet) {
            ChildEditSheetView(
                initialName: profile.child.name,
                initialBirthDate: profile.child.birthDate,
                saveAction: model.updateCurrentChild(name:birthDate:)
            )
        }
        .sheet(isPresented: $showingInviteCaregiverSheet) {
            InviteCaregiverSheetView(inviteAction: model.inviteCaregiver(displayName:))
        }
        .confirmationDialog(
            "Archive \(profile.child.name)?",
            isPresented: $showingArchiveConfirmation,
            titleVisibility: .visible
        ) {
            Button("Archive Child", role: .destructive) {
                model.archiveCurrentChild()
            }
        } message: {
            Text("Archived child profiles are hidden from the main flow until restored.")
        }
        .toolbar {
            if profile.canEditChild {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Edit Child") {
                        showingEditChildSheet = true
                    }
                    .accessibilityIdentifier("edit-child-button")
                }
            }

            if profile.canManageSharing {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Invite Caregiver", systemImage: "person.badge.plus") {
                        showingInviteCaregiverSheet = true
                    }
                    .accessibilityIdentifier("invite-caregiver-button")
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
        showsActivation: Bool,
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

            if showsActivation || showsRemoval {
                HStack {
                    if showsActivation {
                        Button("Mark Active") {
                            model.activateCaregiver(membershipID: caregiver.membership.id)
                        }
                        .accessibilityIdentifier("activate-caregiver-\(caregiver.membership.id.uuidString)")
                    }

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
}
