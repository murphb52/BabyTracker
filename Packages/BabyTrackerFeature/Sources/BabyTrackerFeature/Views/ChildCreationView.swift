import BabyTrackerDomain
import SwiftUI

public struct ChildCreationView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    @State private var childName = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Date()

    public var body: some View {
        Form {
            Section {
                Text("Create the first child profile. You can add a birth date now or leave it for later.")
                    .foregroundStyle(.secondary)
            }

            Section("Child") {
                TextField("Child name", text: $childName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("child-name-field")

                Toggle("Add birth date", isOn: $includesBirthDate)

                if includesBirthDate {
                    DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                        .accessibilityIdentifier("child-birth-date-picker")
                }
            }

            Section {
                Button("Create Child Profile") {
                    model.createChild(
                        name: childName,
                        birthDate: includesBirthDate ? birthDate : nil
                    )
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("create-child-button")
            }

            if !model.archivedChildren.isEmpty {
                Section("Archived Profiles") {
                    ForEach(model.archivedChildren) { summary in
                        Button("Restore \(summary.child.name)") {
                            model.restoreChild(id: summary.child.id)
                        }
                        .accessibilityIdentifier("restore-child-\(summary.child.id.uuidString)")
                    }
                }
            }
        }
        .navigationTitle("Add a Child")
        .navigationBarTitleDisplayMode(.inline)
    }
}
