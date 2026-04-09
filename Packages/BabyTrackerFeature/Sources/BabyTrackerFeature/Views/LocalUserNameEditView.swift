import SwiftUI

public struct LocalUserNameEditView: View {
    let initialDisplayName: String
    let saveAction: (String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""

    public init(
        initialDisplayName: String,
        saveAction: @escaping (String) -> Bool
    ) {
        self.initialDisplayName = initialDisplayName
        self.saveAction = saveAction
    }

    public var body: some View {
        Form {
            Section {
                Text("Update the name shown for the active caregiver throughout sharing, event history, and sync activity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Caregiver") {
                TextField("Your name", text: $displayName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("local-user-name-field")
            }
        }
        .navigationTitle("Your Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let didSave = saveAction(displayName)
                    if didSave {
                        dismiss()
                    }
                }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("save-local-user-name-button")
            }
        }
        .onAppear {
            displayName = initialDisplayName
        }
    }
}

#Preview {
    NavigationStack {
        LocalUserNameEditView(initialDisplayName: "Alex Parent") { _ in true }
    }
}
