import BabyTrackerDomain
import SwiftUI
import UIKit

public struct ChildProfileDetailsView: View {
    let viewModel: ChildProfileViewModel
    let editChildAction: () -> Void

    public init(
        viewModel: ChildProfileViewModel,
        editChildAction: @escaping () -> Void
    ) {
        self.viewModel = viewModel
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

            Section("Identity") {
                LabeledContent("Name") {
                    Text(viewModel.childName)
                        .accessibilityIdentifier("child-profile-name")
                }

                LabeledContent("Birth Date") {
                    Text(birthDateText)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Child Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.canEditChild {
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
        if let imageData = viewModel.child?.imageData, let uiImage = UIImage(data: imageData) {
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
                Text(viewModel.childName.prefix(1).uppercased())
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var birthDateText: String {
        if let birthDate = viewModel.child?.birthDate {
            return birthDate.formatted(date: .abbreviated, time: .omitted)
        }
        return "Not set"
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildProfileDetailsView(
            viewModel: ChildProfileViewModel(appModel: model),
            editChildAction: {}
        )
    }
}
