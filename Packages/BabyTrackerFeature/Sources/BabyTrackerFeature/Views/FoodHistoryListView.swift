import BabyTrackerDomain
import SwiftUI

/// Lists every food the child has had so a caregiver can browse and pick one.
struct FoodHistoryListView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .food)

    let foodNames: [String]
    let selectedFoodName: String
    let selectFood: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleFoodNames, id: \.self) { name in
                    Button {
                        selectFood(name)
                        dismiss()
                    } label: {
                        HStack {
                            Text(name).foregroundStyle(.primary)
                            Spacer()
                            if isSelected(name) {
                                Image(systemName: "checkmark").foregroundStyle(Self.eventColor)
                            }
                        }
                    }
                    .accessibilityAddTraits(isSelected(name) ? .isSelected : [])
                }
            }
            .overlay {
                if foodNames.isEmpty {
                    ContentUnavailableView("No Foods Yet", systemImage: "fork.knife", description: Text("Foods you log will appear here."))
                } else if visibleFoodNames.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Search foods")
            .navigationTitle("All Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .tint(Self.eventColor)
    }

    private var sortedFoodNames: [String] {
        foodNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var visibleFoodNames: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedFoodNames }
        return sortedFoodNames.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private func isSelected(_ name: String) -> Bool {
        selectedFoodName.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(name) == .orderedSame
    }
}

#Preview("All foods") {
    FoodHistoryListView(
        foodNames: ["Porridge", "Banana", "Avocado", "Sweet Potato", "Broccoli", "Pear", "Pasta", "Apple", "Yoghurt"],
        selectedFoodName: "Banana",
        selectFood: { _ in }
    )
}

#Preview("No foods") {
    FoodHistoryListView(foodNames: [], selectedFoodName: "", selectFood: { _ in })
}
