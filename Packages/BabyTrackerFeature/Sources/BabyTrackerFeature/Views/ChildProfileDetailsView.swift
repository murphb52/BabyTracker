import BabyTrackerDomain
import SwiftUI
import UIKit

public struct ChildProfileDetailsView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let editChildAction: () -> Void

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        editChildAction: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.editChildAction = editChildAction
    }

    public var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    profileImageView
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

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

            Section("Feeding") {
                Picker("Bottle volume unit", selection: volumeUnitBinding) {
                    ForEach(FeedVolumeUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .accessibilityIdentifier("child-feed-volume-unit-picker")
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

    @ViewBuilder
    private var profileImageView: some View {
        if let imageData = profile.child.imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 88, height: 88)
                Text(profile.child.name.prefix(1).uppercased())
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var birthDateText: String {
        if let birthDate = profile.child.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }

        return "Not set"
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
