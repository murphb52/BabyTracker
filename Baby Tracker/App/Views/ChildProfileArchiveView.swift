import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileArchiveView: View {
    let profile: ChildProfileScreenState
    let archiveAction: () -> Void

    var body: some View {
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
