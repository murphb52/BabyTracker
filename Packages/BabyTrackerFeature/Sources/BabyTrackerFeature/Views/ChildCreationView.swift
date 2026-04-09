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
        Form {
            Section {
                createChildHeaderCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
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
                .padding(.vertical, 4)
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
                .controlSize(.large)
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
            } header: {
                Text("Restore from Backup")
            } footer: {
                Text("Restore a child profile and all events from a Nest JSON backup file.")
                    .font(.caption)
            }
        }
    }

    private var createChildHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Create a new profile", systemImage: "person.crop.circle.badge.plus")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Set up your child’s profile so feeding, sleep, and nappy logs stay organized in one place.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Text("You can add a birth date now or skip it and update later.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
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

    @ViewBuilder
    private var profileImageView: some View {
        if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "camera.fill")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

private struct RestoreImportSuccess {
    let childName: String
    let result: CSVImportResult
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ChildCreationView(model: model)
    }
}
