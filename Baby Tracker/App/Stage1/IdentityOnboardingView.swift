import BabyTrackerFeature
import SwiftUI

struct IdentityOnboardingView: View {
    let model: Stage1AppModel

    @State private var displayName = ""

    var body: some View {
        Form {
            Section {
                Text("Set up the caregiver identity for this device before creating a child profile.")
                    .foregroundStyle(.secondary)
            }

            Section("Caregiver") {
                TextField("Your name", text: $displayName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("identity-name-field")
            }

            Section {
                Button("Save and Continue") {
                    model.createLocalUser(displayName: displayName)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("identity-save-button")
            }
        }
    }
}
