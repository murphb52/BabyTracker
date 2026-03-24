import SwiftUI

struct ChildEditSheetView: View {
    let initialName: String
    let initialBirthDate: Date?
    let saveAction: (_ name: String, _ birthDate: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    TextField("Child name", text: $name)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("edit-child-name-field")

                    Toggle("Add birth date", isOn: $includesBirthDate)

                    if includesBirthDate {
                        DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Edit Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAction(name, includesBirthDate ? birthDate : nil)
                        dismiss()
                    }
                    .accessibilityIdentifier("save-child-edit-button")
                }
            }
            .onAppear {
                name = initialName
                if let initialBirthDate {
                    includesBirthDate = true
                    birthDate = initialBirthDate
                }
            }
        }
    }
}
