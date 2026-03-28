import BabyTrackerDomain
import PhotosUI
import SwiftUI

public struct ChildCreationView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    @State private var childName = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Date()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    public var body: some View {
        Form {
            Section {
                Text("Create a child profile. You can add a birth date now or leave it for later.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        profileImageView
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, Color.accentColor)
                                    .offset(x: 4, y: 4)
                            }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .listRowBackground(Color.clear)
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
                        birthDate: includesBirthDate ? birthDate : nil,
                        imageData: selectedImageData
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
        .onChange(of: selectedItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data),
                      let compressed = ImageCompressor.compress(uiImage) else { return }
                selectedImageData = compressed
            }
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
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
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}
