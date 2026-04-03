import SwiftUI

public struct ChildProfileImportChoiceView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        List {
            Section {
                Text("Choose where you'd like to import data from.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    ChildProfileImportView(appModel: model)
                } label: {
                    importSourceRow(
                        icon: "bird.fill",
                        iconColor: .teal,
                        title: "Huckleberry",
                        description: "Import from a CSV file exported from the Huckleberry app",
                        accessibilityIdentifier: "import-from-huckleberry"
                    )
                }

                NavigationLink {
                    ChildProfileNestImportView(appModel: model)
                } label: {
                    importSourceRow(
                        icon: "square.and.arrow.down",
                        iconColor: .blue,
                        title: "Nest",
                        description: "Import from a JSON file previously exported from Nest",
                        accessibilityIdentifier: "import-from-nest"
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func importSourceRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        accessibilityIdentifier: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}
