import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct ChildPickerView: View {
    let model: AppModel

    var body: some View {
        List {
            Section {
                Text("Choose which child profile to open on this device.")
                    .foregroundStyle(.secondary)
            }

            Section("Children") {
                ForEach(model.activeChildren) { summary in
                    Button {
                        model.selectChild(id: summary.child.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(summary.child.name)
                                .font(.headline)

                            Text(summary.membership.role == .owner ? "Owner access" : "Caregiver access")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("child-picker-\(summary.child.id.uuidString)")
                }
            }
        }
    }
}
