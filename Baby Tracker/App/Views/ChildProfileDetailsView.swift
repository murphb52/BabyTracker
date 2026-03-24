import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildProfileDetailsView: View {
    let profile: ChildProfileScreenState
    let editChildAction: () -> Void

    var body: some View {
        List {
            Section("Child") {
                LabeledContent("Name") {
                    Text(profile.child.name)
                        .accessibilityIdentifier("child-profile-name")
                }

                LabeledContent("Birth Date") {
                    Text(birthDateText)
                }
            }

            Section("Account") {
                LabeledContent("Signed In As") {
                    Text(profile.localUser.displayName)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if profile.canEditChild {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        editChildAction()
                    }
                    .accessibilityIdentifier("edit-child-button")
                }
            }
        }
    }

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not set"
    }
}
