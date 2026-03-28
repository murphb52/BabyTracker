import SwiftUI

public struct NukeAllDataView: View {
    let nukeAction: () -> Void

    @State private var showingFirstConfirmation = false
    @State private var showingFinalConfirmation = false

    public init(nukeAction: @escaping () -> Void) {
        self.nukeAction = nukeAction
    }

    public var body: some View {
        List {
            Section {
                Text("This is a complete account reset. It cannot be undone.")
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
            }

            Section("What will be erased") {
                Label("All children you own and their event history", systemImage: "person.crop.circle.badge.minus")
                Label("Your account identity on this device", systemImage: "person.slash")
                Label("All local data including sync history", systemImage: "internaldrive")
            }
            .foregroundStyle(.secondary)

            Section("What will happen to others") {
                Label("Caregivers will lose access to your children", systemImage: "person.2.slash")
                Label("Children you track as a caregiver are not deleted — they remain under their owner's account", systemImage: "checkmark.shield")
            }
            .foregroundStyle(.secondary)

            Section {
                Button("Erase Everything", role: .destructive) {
                    showingFirstConfirmation = true
                }
                .accessibilityIdentifier("nuke-all-data-button")
            }
        }
        .navigationTitle("Erase Everything")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .alert("Are you absolutely sure?", isPresented: $showingFirstConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                showingFinalConfirmation = true
            }
        } message: {
            Text("This will permanently remove all your children, event records, and your account from this device and iCloud. This cannot be undone.")
        }
        .alert("Final confirmation", isPresented: $showingFinalConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Erase Everything", role: .destructive) {
                nukeAction()
            }
        } message: {
            Text("Tap \"Erase Everything\" one last time to confirm. All owned children and your account will be permanently deleted.")
        }
    }
}
