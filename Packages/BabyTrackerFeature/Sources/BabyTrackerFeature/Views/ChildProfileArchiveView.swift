import BabyTrackerDomain
import SwiftUI

public struct ChildProfileArchiveView: View {
    let profile: ChildProfileScreenState
    let archiveAction: () -> Void

    public init(
        profile: ChildProfileScreenState,
        archiveAction: @escaping () -> Void
    ) {
        self.profile = profile
        self.archiveAction = archiveAction
    }

    public var body: some View {
        List {
            Section {
                Text("Archived child profiles are removed from the main flow until restored.")
                    .foregroundStyle(.secondary)

                Text("Historical events remain available in storage and can be restored later from the child list.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Archive \(profile.child.name)", role: .destructive) {
                    archiveAction()
                }
                .accessibilityIdentifier("archive-child-button")
            }
        }
        .navigationTitle("Archive Child")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }
}
