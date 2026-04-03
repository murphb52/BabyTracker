import BabyTrackerDomain
import SwiftUI

public struct ChildProfileSharingView: View {
    let model: AppModel
    let viewModel: ChildProfileViewModel
    let shareChildAction: () -> Void

    public init(
        model: AppModel,
        viewModel: ChildProfileViewModel,
        shareChildAction: @escaping () -> Void
    ) {
        self.model = model
        self.viewModel = viewModel
        self.shareChildAction = shareChildAction
    }

    public var body: some View {
        List {
            if viewModel.canManageSharing {
                Section("Invite") {
                    Button {
                        shareChildAction()
                    } label: {
                        Label("Share Child", systemImage: "person.crop.circle.badge.plus")
                    }
                    .disabled(!viewModel.canShareChild)
                    .accessibilityIdentifier("share-child-button")

                    if let shareUnavailableMessage {
                        Text(shareUnavailableMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("share-child-unavailable-message")
                    }
                }
            }

            if let owner = viewModel.owner {
                Section("Owner") {
                    caregiverRow(for: owner, showsRemoval: false)
                }
            }

            if !viewModel.activeCaregivers.isEmpty {
                Section("Active Caregivers") {
                    ForEach(viewModel.activeCaregivers) { caregiver in
                        caregiverRow(
                            for: caregiver,
                            showsRemoval: viewModel.canManageSharing
                        )
                    }
                }
            }

            if !viewModel.pendingShareInvites.isEmpty {
                Section("Pending Invitations") {
                    ForEach(viewModel.pendingShareInvites) { invite in
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

            if !viewModel.removedCaregivers.isEmpty {
                Section("Past Access") {
                    ForEach(viewModel.removedCaregivers) { caregiver in
                        caregiverRow(for: caregiver, showsRemoval: false)
                    }
                }
            }
        }
        .navigationTitle("Sharing & Caregivers")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }

    private var shareUnavailableMessage: String? {
        guard !viewModel.canShareChild else { return nil }

        if viewModel.cloudKitStatus.isAccountUnavailable {
            return "Sharing is unavailable until iCloud backup is available. Check the iCloud Sync screen for details."
        }

        if let detailMessage = viewModel.cloudKitStatus.detailMessage {
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

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildProfileSharingView(
            model: model,
            viewModel: ChildProfileViewModel(appModel: model),
            shareChildAction: {}
        )
    }
}
