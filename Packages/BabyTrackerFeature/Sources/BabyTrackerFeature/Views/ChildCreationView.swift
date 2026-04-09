import BabyTrackerDomain
import PhotosUI
import SwiftUI

public struct ChildCreationView: View {
    @Environment(\.dismiss) private var dismiss

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
    @State private var importSuccess: RestoreImportSuccess?

    public var body: some View {
        Group {
            if let importSuccess {
                importSuccessView(importSuccess)
            } else {
                creationForm
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

    private var creationForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard

                profileImagePickerCard

                childDetailsCard

                createChildButton

                importCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Welcome", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Create your child profile")
                .font(.title2.weight(.bold))

            Text("Add a name, optional birth date, and a photo so your timeline starts with the right context.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.18),
                            Color.accentColor.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var profileImagePickerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profile photo")
                .font(.headline)

            HStack(spacing: 16) {
                let currentSelectedImageData = selectedImageData

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ChildProfileImagePickerLabel(imageData: currentSelectedImageData)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose a photo")
                        .font(.subheadline.weight(.semibold))

                    Text("This makes it easier to spot the right profile later.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .cardStyle()
    }

    private var childDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Child details")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField("Child name", text: $childName)
                    .textInputAutocapitalization(.words)
                    .accessibilityIdentifier("child-name-field")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }

            Toggle("Add birth date", isOn: $includesBirthDate)

            if includesBirthDate {
                DatePicker("Birth date", selection: $birthDate, displayedComponents: .date)
                    .accessibilityIdentifier("child-birth-date-picker")
            }
        }
        .cardStyle()
    }

    private var createChildButton: some View {
        Button("Create Child Profile") {
            model.createChild(
                name: childName,
                birthDate: includesBirthDate ? birthDate : nil,
                imageData: selectedImageData
            )
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("create-child-button")
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Restore from backup", systemImage: "square.and.arrow.down")
                .font(.headline)

            Text("Import a child profile and events from a Nest JSON backup file.")
                .font(.caption)
                .foregroundStyle(.secondary)

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
                    Label("Import from Nest Backup", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("import-from-nest-backup-button")
            }
        }
        .cardStyle()
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
                    let output = try await model.performImportChildFromNest(data: data, onProgress: { _, _ in })
                    importSuccess = RestoreImportSuccess(
                        childName: output.child.name,
                        result: output.importResult
                    )
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

    private func importSuccessView(_ success: RestoreImportSuccess) -> some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("Restore Complete")
                        .font(.title2)
                        .bold()

                    Text("\(success.childName) was restored as a new child profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Imported") {
                Label("Child profile", systemImage: "person.crop.circle")
                Label(
                    "\(success.result.importedCount) event\(success.result.importedCount == 1 ? "" : "s")",
                    systemImage: "checklist"
                )
            }

            if success.result.totalSkipped > 0 {
                Section {
                    Label(
                        "\(success.result.totalSkipped) item\(success.result.totalSkipped == 1 ? "" : "s") skipped",
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(.orange)

                    ForEach(success.result.skippedReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .accessibilityIdentifier("restored-child-continue-button")
            }
        }
        .listStyle(.insetGrouped)
    }
}

private struct RestoreImportSuccess {
    let childName: String
    let result: CSVImportResult
}

private struct ChildProfileImagePickerLabel: View {
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

private extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
}
#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildCreationView(model: model)
    }
}
