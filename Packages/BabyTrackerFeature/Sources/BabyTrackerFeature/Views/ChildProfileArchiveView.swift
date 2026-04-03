import BabyTrackerDomain
import SwiftUI

public struct ChildProfileArchiveView: View {
    let childName: String
    let archiveAction: () -> Void

    public init(
        childName: String,
        archiveAction: @escaping () -> Void
    ) {
        self.childName = childName
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
                Button("Archive \(childName)", role: .destructive) {
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
