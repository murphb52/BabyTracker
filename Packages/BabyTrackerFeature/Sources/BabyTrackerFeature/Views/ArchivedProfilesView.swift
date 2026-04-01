import SwiftUI

public struct ArchivedProfilesView: View {
    let model: AppModel

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        let archivedChildren = model.archivedChildren.map(ArchivedProfileRowState.init)

        List {
            Section {
                Text("Archived profiles are hidden from the active child list until you restore them.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Section("Archived Profiles") {
                ArchivedProfilesSection(
                    archivedChildren: archivedChildren,
                    restoreChild: model.restoreChild(id:)
                )
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Archived Profiles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArchivedProfilesSection: View {
    let archivedChildren: [ArchivedProfileRowState]
    let restoreChild: (UUID) -> Void

    var body: some View {
        SwiftUI.ForEach<[ArchivedProfileRowState], UUID, ArchivedProfileRowView>(
            archivedChildren,
            id: \.id
        ) { summary in
            ArchivedProfileRowView(
                summary: summary,
                restoreChild: restoreChild
            )
        }
    }
}

private struct ArchivedProfileRowState: Identifiable {
    let id: UUID
    let name: String

    init(summary: ChildSummary) {
        self.id = summary.child.id
        self.name = summary.child.name
    }
}

private struct ArchivedProfileRowView: View {
    let summary: ArchivedProfileRowState
    let restoreChild: (UUID) -> Void

    var body: some View {
        Button {
            restoreChild(summary.id)
        } label: {
            HStack {
                Text(summary.name)
                    .foregroundStyle(.primary)
                Spacer()
                Text("Restore")
                    .foregroundStyle(Color.accentColor)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("restore-child-\(summary.id.uuidString)")
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        ArchivedProfilesView(model: model)
    }
}
