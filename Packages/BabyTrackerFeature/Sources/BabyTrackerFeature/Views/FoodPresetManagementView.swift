import BabyTrackerDomain
import SwiftUI

public struct FoodPresetManagementView: View {
    let updatePreset: (UUID, String, Double, FoodUnit, String?) -> Bool
    let deletePreset: (UUID) -> Bool
    let reorderPresets: ([UUID]) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var orderedPresets: [FoodPreset]
    @State private var editingPreset: FoodPreset?

    public init(
        presets: [FoodPreset],
        updatePreset: @escaping (UUID, String, Double, FoodUnit, String?) -> Bool,
        deletePreset: @escaping (UUID) -> Bool,
        reorderPresets: @escaping ([UUID]) -> Bool
    ) {
        _orderedPresets = State(initialValue: presets)
        self.updatePreset = updatePreset
        self.deletePreset = deletePreset
        self.reorderPresets = reorderPresets
    }

    public var body: some View {
        NavigationStack {
            List {
                if orderedPresets.isEmpty {
                    ContentUnavailableView("No Food Presets", systemImage: "fork.knife", description: Text("Save a preset when logging Food."))
                }
                ForEach(orderedPresets) { preset in
                    Button { editingPreset = preset } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.foodName)
                                Text(preset.displayAmount).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { _ = deletePreset(orderedPresets[index].id) }
                    orderedPresets.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    orderedPresets.move(fromOffsets: source, toOffset: destination)
                    _ = reorderPresets(orderedPresets.map(\.id))
                }
            }
            .navigationTitle("Food Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { EditButton() }
            }
            .sheet(item: $editingPreset) { preset in
                FoodPresetEditorView(preset: preset) { name, amount, unit, customLabel in
                    let didSave = updatePreset(preset.id, name, amount, unit, customLabel)
                    if didSave, let index = orderedPresets.firstIndex(where: { $0.id == preset.id }) {
                        orderedPresets[index].foodName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        orderedPresets[index].amount = amount
                        orderedPresets[index].unit = unit
                        orderedPresets[index].customUnitLabel = unit == .custom ? customLabel : nil
                    }
                    return didSave
                }
            }
        }
    }
}

#Preview {
    FoodPresetManagementView(presets: [], updatePreset: { _, _, _, _, _ in true }, deletePreset: { _ in true }, reorderPresets: { _ in true })
}
