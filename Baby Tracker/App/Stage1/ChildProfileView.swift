import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    @State private var showingEditChildSheet = false
    @State private var showingArchiveConfirmation = false

    var body: some View {
        @Bindable var bindableModel = model

        List {
            if let syncBannerState = profile.syncBannerState {
                Section {
                    Label(syncBannerState.message, systemImage: syncBannerIcon(for: syncBannerState))
                        .font(.subheadline)
                        .foregroundStyle(syncBannerColor(for: syncBannerState))
                }
            }

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
        .sheet(item: $bindableModel.shareSheetState) { shareState in
            CloudKitShareSheetView(shareState: shareState, childName: profile.child.name)
                .onDisappear {
                    model.dismissShareSheet()
                    model.refreshAfterShareSheet()
                }
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
                    Button("Share", systemImage: "square.and.arrow.up") {
                        model.presentShareSheet()
                    }
                    .disabled(!profile.canShareChild)
                    .accessibilityIdentifier("share-child-button")
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

    private func syncBannerIcon(for state: SyncBannerState) -> String {
        switch state {
        case .syncing:
            "arrow.triangle.2.circlepath"
        case .pendingSync:
            "clock.badge.exclamationmark"
        case .syncUnavailable:
            "icloud.slash"
        case .lastSyncFailed:
            "exclamationmark.icloud"
        }
    }

    private func syncBannerColor(for state: SyncBannerState) -> Color {
        switch state {
        case .syncing:
            .blue
        case .pendingSync:
            .orange
        case .syncUnavailable, .lastSyncFailed:
            .red
        }
    }
}
