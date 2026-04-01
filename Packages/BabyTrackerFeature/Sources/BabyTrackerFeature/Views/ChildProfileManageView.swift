import SwiftUI

public struct ChildProfileManageView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let archiveAction: () -> Void
    let hardDeleteAction: () -> Void

    @State private var showingLeaveConfirmation = false

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        archiveAction: @escaping () -> Void,
        hardDeleteAction: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.archiveAction = archiveAction
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section {
                Text("Manage changes that affect access to \(profile.child.name) or remove this child from your active workspace.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("Child Lifecycle") {
                if profile.canArchiveChild {
                    NavigationLink {
                        ChildProfileArchiveView(
                            profile: profile,
                            archiveAction: archiveAction
                        )
                    } label: {
                        lifecycleRow(
                            title: "Archive Child",
                            detail: "Hide this child until you restore the profile later.",
                            accessibilityIdentifier: "profile-manage-archive-row"
                        )
                    }
                }

                if profile.canLeaveShare {
                    Button(role: .destructive) {
                        showingLeaveConfirmation = true
                    } label: {
                        lifecycleRow(
                            title: "Leave Profile",
                            detail: "Remove this child from this device. You can rejoin if invited again.",
                            accessibilityIdentifier: "profile-manage-leave-row",
                            titleColor: .red
                        )
                    }
                    .accessibilityIdentifier("profile-manage-leave-row")
                }

                if profile.canHardDelete {
                    NavigationLink {
                        ChildProfileHardDeleteView(
                            childName: profile.child.name,
                            hardDeleteAction: hardDeleteAction
                        )
                    } label: {
                        lifecycleRow(
                            title: "Delete Child Permanently",
                            detail: "Erase this child's profile and data from this device and iCloud.",
                            accessibilityIdentifier: "profile-manage-hard-delete-row",
                            titleColor: .red
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Manage Child")
        .navigationBarTitleDisplayMode(.inline)
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

    private func lifecycleRow(
        title: String,
        detail: String,
        accessibilityIdentifier: String,
        titleColor: Color = .primary
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(titleColor)

            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildProfileManageView(
                model: model,
                profile: profile,
                archiveAction: {},
                hardDeleteAction: {}
            )
        }
    }
}
