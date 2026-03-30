import SwiftUI

public struct ChildProfileHardDeleteView: View {
    let childName: String
    let hardDeleteAction: () -> Void

    @State private var showingConfirmation = false

    public init(childName: String, hardDeleteAction: @escaping () -> Void) {
        self.childName = childName
        self.hardDeleteAction = hardDeleteAction
    }

    public var body: some View {
        List {
            Section {
                Text("This permanently removes \(childName)'s profile and all logged events from this device and iCloud.")
                    .foregroundStyle(.secondary)

                Text("Other children in your account are not affected. This cannot be undone.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Delete \(childName)'s Data", role: .destructive) {
                    showingConfirmation = true
                }
                .accessibilityIdentifier("hard-delete-all-data-button")
            }
        }
        .navigationTitle("Hard Delete")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .alert("Delete \(childName)'s data?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                hardDeleteAction()
            }
        } message: {
            Text("This will permanently remove \(childName)'s profile, memberships, and all event records. This cannot be undone.")
        }
    }
}
