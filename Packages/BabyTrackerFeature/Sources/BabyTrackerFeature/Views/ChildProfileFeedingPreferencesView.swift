import BabyTrackerDomain
import SwiftUI

public struct ChildProfileFeedingPreferencesView: View {
    let model: AppModel
    let profile: ChildProfileScreenState

    public init(
        model: AppModel,
        profile: ChildProfileScreenState
    ) {
        self.model = model
        self.profile = profile
    }

    public var body: some View {
        List {
            Section {
                Picker("Bottle volume unit", selection: volumeUnitBinding) {
                    ForEach(FeedVolumeUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .accessibilityIdentifier("child-feed-volume-unit-picker")
            } header: {
                Text("Feeding")
            } footer: {
                Text("This unit is used when entering and displaying bottle feeds for \(profile.child.name).")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Feeding Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var volumeUnitBinding: Binding<FeedVolumeUnit> {
        Binding(
            get: { profile.child.preferredFeedVolumeUnit },
            set: { selectedUnit in
                model.updateCurrentChild(
                    name: profile.child.name,
                    birthDate: profile.child.birthDate,
                    imageData: profile.child.imageData,
                    preferredFeedVolumeUnit: selectedUnit
                )
            }
        )
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        if let profile = model.profile {
            ChildProfileFeedingPreferencesView(model: model, profile: profile)
        }
    }
}
