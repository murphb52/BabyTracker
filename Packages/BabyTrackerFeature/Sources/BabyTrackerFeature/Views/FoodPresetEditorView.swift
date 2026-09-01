import BabyTrackerDomain
import SwiftUI

public struct FoodPresetEditorView: View {
    let preset: FoodPreset
    let saveAction: (String, Double, FoodUnit, String?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amountText: String
    @State private var unit: FoodUnit
    @State private var customLabel: String

    public init(preset: FoodPreset, saveAction: @escaping (String, Double, FoodUnit, String?) -> Bool) {
        self.preset = preset
        self.saveAction = saveAction
        _name = State(initialValue: preset.foodName)
        _amountText = State(initialValue: preset.amount == preset.amount.rounded() ? String(Int(preset.amount)) : String(preset.amount))
        _unit = State(initialValue: preset.unit)
        _customLabel = State(initialValue: preset.customUnitLabel ?? "")
    }

    public var body: some View {
        NavigationStack {
            Form {
                TextField("Food name", text: $name)
                TextField("Amount", text: $amountText).keyboardType(.decimalPad)
                Picker("Unit", selection: $unit) {
                    ForEach(FoodUnit.allCases, id: \.self) { Text($0.pickerTitle).tag($0) }
                }
                if unit == .custom { TextField("Custom unit", text: $customLabel) }
            }
            .navigationTitle("Edit Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
                        if saveAction(name, amount, unit, unit == .custom ? customLabel : nil) { dismiss() }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
              amount.isFinite, amount > 0 else { return false }
        return unit != .custom || !customLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    let preset = try! FoodPreset(
        childID: UUID(),
        foodName: "Porridge",
        amount: 0.5,
        unit: .bowl,
        sortOrder: 0,
        createdBy: UUID()
    )
    FoodPresetEditorView(preset: preset) { _, _, _, _ in true }
}
