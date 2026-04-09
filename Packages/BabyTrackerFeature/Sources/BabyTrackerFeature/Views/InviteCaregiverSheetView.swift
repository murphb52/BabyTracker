import SwiftUI

public struct InviteCaregiverSheetView: View {
    let inviteAction: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""

    public init(inviteAction: @escaping (String) -> Void) {
        self.inviteAction = inviteAction
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Invite another caregiver to view and update this child profile through iCloud sharing.")
                        .foregroundStyle(.secondary)
                }

                Section("Caregiver") {
                    TextField("Caregiver name", text: $displayName)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("invite-caregiver-name-field")
                }
            }
            .navigationTitle("Invite Caregiver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        inviteAction(displayName)
                        dismiss()
                    }
                    .accessibilityIdentifier("invite-caregiver-save-button")
                }
            }
        }
    }
}
