import SwiftUI

public struct ChildProfileHardDeleteView: View {
    let hardDeleteAction: () -> Void

    @State private var showingConfirmation = false

    public init(hardDeleteAction: @escaping () -> Void) {
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section {
                Text("This permanently removes local records on this device and attempts to remove synced iCloud records for your children.")
                    .foregroundStyle(.secondary)

                Text("Use this only if you want to start over. This cannot be undone.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Delete All Data", role: .destructive) {
                    showingConfirmation = true
                }
                .accessibilityIdentifier("hard-delete-all-data-button")
            }
        }
        .navigationTitle("Hard Delete")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .alert("Delete all data?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                hardDeleteAction()
            }
        } message: {
            Text("This will remove all profile, membership, and event records and cannot be undone.")
        }
    }
}
