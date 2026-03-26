import BabyTrackerDomain
import SwiftUI
import UIKit

public struct ChildProfileDetailsView: View {
    let profile: ChildProfileScreenState
    let editChildAction: () -> Void

    public init(
        profile: ChildProfileScreenState,
        editChildAction: @escaping () -> Void
    ) {
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
}
