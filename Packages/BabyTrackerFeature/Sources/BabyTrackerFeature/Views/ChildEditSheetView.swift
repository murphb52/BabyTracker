import PhotosUI
import SwiftUI

public struct ChildEditSheetView: View {
    let initialName: String
    let initialBirthDate: Date?
    let initialImageData: Data?
    let saveAction: (_ name: String, _ birthDate: Date?, _ imageData: Data?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var includesBirthDate = false
    @State private var birthDate = Date()
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    public init(
        initialName: String,
        initialBirthDate: Date?,
        initialImageData: Data? = nil,
        saveAction: @escaping (_ name: String, _ birthDate: Date?, _ imageData: Data?) -> Void
    ) {
        self.initialName = initialName
        self.initialBirthDate = initialBirthDate
        self.initialImageData = initialImageData
        self.saveAction = saveAction
    }

    public var body: some View {
        let currentSelectedImageData = selectedImageData

        return NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ChildEditImagePickerLabel(imageData: currentSelectedImageData)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

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
                        saveAction(name, includesBirthDate ? birthDate : nil, selectedImageData)
                        dismiss()
                    }
                    .accessibilityIdentifier("save-child-edit-button")
                }
            }
            .onAppear {
                name = initialName
                selectedImageData = initialImageData
                if let initialBirthDate {
                    includesBirthDate = true
                    birthDate = initialBirthDate
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    guard let data = try? await newItem?.loadTransferable(type: Data.self),
                          let uiImage = UIImage(data: data),
                          let compressed = ImageCompressor.compress(uiImage) else { return }
                    selectedImageData = compressed
                }
            }
        }
    }
}

private struct ChildEditImagePickerLabel: View {
    let imageData: Data?

    var body: some View {
        profileImageView
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.accentColor)
                    .offset(x: 4, y: 4)
            }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
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
