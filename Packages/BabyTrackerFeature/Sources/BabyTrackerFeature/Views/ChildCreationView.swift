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
    @State private var isImportPickerPresented = false
    @State private var importInProgress = false
    @State private var importError: String?

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

            Section {
                if importInProgress {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Importing…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button {
                        isImportPickerPresented = true
                    } label: {
                        Label("Import from Nest Backup", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("import-from-nest-backup-button")
                }
            } footer: {
                Text("Restore a child profile and all events from a Nest JSON backup file.")
                    .font(.caption)
            }
        }
        .navigationTitle("Add a Child")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImportPickerPresented,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportFileSelection(result)
        }
        .alert("Import Failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
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

    // MARK: - Import handling

    private func handleImportFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard let data = try? Data(contentsOf: url) else {
                importError = "Could not read the selected file."
                return
            }
            importInProgress = true
            Task { @MainActor in
                defer { importInProgress = false }
                do {
                    _ = try await model.performImportChildFromNest(data: data, onProgress: { _, _ in })
                } catch {
                    if let localizedError = error as? LocalizedError,
                       let description = localizedError.errorDescription {
                        importError = description
                    } else {
                        importError = "Import failed. Please check the file and try again."
                    }
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
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

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildCreationView(model: model)
    }
}
