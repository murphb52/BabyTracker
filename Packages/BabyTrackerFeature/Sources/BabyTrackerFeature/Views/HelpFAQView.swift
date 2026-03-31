import SwiftUI

public struct HelpFAQView: View {
    @State private var expandedItemIDs: Set<String>

    public init(expandedItemIDs: Set<String> = []) {
        _expandedItemIDs = State(initialValue: expandedItemIDs)
    }

    public var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Baby Tracker explains what was logged and how the app calculates its summaries. It does not provide medical advice or diagnosis.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(HelpFAQContent.sections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.items) { item in
                        DisclosureGroup(
                            isExpanded: binding(for: item.id),
                            content: {
                                Text(item.answer)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 4)
                                    .padding(.bottom, 2)
                            },
                            label: {
                                Text(item.title)
                                    .font(.body.weight(.semibold))
                                    .padding(.vertical, 4)
                            }
                        )
                        .accessibilityIdentifier("help-faq-\(item.id)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func binding(for itemID: String) -> Binding<Bool> {
        Binding(
            get: { expandedItemIDs.contains(itemID) },
            set: { isExpanded in
                if isExpanded {
                    expandedItemIDs.insert(itemID)
                } else {
                    expandedItemIDs.remove(itemID)
                }
            }
        )
    }
}

#Preview("Collapsed") {
    NavigationStack {
        HelpFAQView()
    }
}

#Preview("Expanded") {
    NavigationStack {
        HelpFAQView(expandedItemIDs: ["summary-range-picker"])
    }
}
