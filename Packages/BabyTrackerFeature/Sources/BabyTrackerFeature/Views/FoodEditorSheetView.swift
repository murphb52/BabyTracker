import BabyTrackerDomain
import SwiftUI

public struct FoodEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .food)

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let recentFoodNames: [String]
    let saveAction: (Date, String, Double, FoodUnit, String?, Bool) -> Bool
    let updatePreset: (UUID, String, Double, FoodUnit, String?) -> Bool
    let deletePreset: (UUID) -> Bool
    let reorderPresets: ([UUID]) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var occurredAt: Date
    @State private var foodName: String
    @State private var amountText: String
    @State private var unit: FoodUnit
    @State private var customUnitLabel: String
    @State private var saveAsPreset = false
    @State private var showingPresets = false
    @State private var showingDeleteConfirmation = false
    @State private var displayedPresets: [FoodPreset]
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        recentFoodNames: [String],
        presets: [FoodPreset],
        initialOccurredAt: Date,
        initialFoodName: String = "",
        initialAmount: Double? = nil,
        initialUnit: FoodUnit = .bowl,
        initialCustomUnitLabel: String? = nil,
        initialTimePreset: QuickTimeSelectorView.TimePreset = .now,
        deleteAction: (() -> Void)? = nil,
        updatePreset: @escaping (UUID, String, Double, FoodUnit, String?) -> Bool,
        deletePreset: @escaping (UUID) -> Bool,
        reorderPresets: @escaping ([UUID]) -> Bool,
        saveAction: @escaping (Date, String, Double, FoodUnit, String?, Bool) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.recentFoodNames = recentFoodNames
        self.deleteAction = deleteAction
        self.updatePreset = updatePreset
        self.deletePreset = deletePreset
        self.reorderPresets = reorderPresets
        self.saveAction = saveAction
        _occurredAt = State(initialValue: initialOccurredAt)
        _foodName = State(initialValue: initialFoodName)
        _amountText = State(initialValue: initialAmount.map(Self.editableAmount) ?? "")
        _unit = State(initialValue: initialUnit)
        _customUnitLabel = State(initialValue: initialCustomUnitLabel ?? "")
        _displayedPresets = State(initialValue: presets)
        self.initialTimePreset = initialTimePreset
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)
                presetSection
                foodSection
                amountSection
                if let validationMessage {
                    Section { Text(validationMessage).foregroundStyle(.red) }
                }
                Section("When?") {
                    QuickTimeSelectorView(selection: $occurredAt, initialPreset: initialTimePreset, buttonColor: Self.eventColor)
                        .accessibilityIdentifier("food-time-selector")
                }
                if deleteAction == nil {
                    Section {
                        Toggle("Save as preset", isOn: $saveAsPreset)
                            .accessibilityIdentifier("food-save-preset-toggle")
                    }
                }
                if deleteAction != nil {
                    Section {
                        Button("Delete Food Entry", role: .destructive) { showingDeleteConfirmation = true }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Self.eventColor.opacity(0.08))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) { save() }.disabled(validationMessage != nil)
                }
            }
            .sheet(isPresented: $showingPresets) {
                FoodPresetManagementView(
                    presets: displayedPresets,
                    updatePreset: updateDisplayedPreset,
                    deletePreset: deleteDisplayedPreset,
                    reorderPresets: reorderDisplayedPresets
                )
            }
            .alert("Delete Food Entry?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) { deleteAction?(); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This event will be permanently removed.")
            }
        }
        .tint(Self.eventColor)
    }

    @ViewBuilder
    private var presetSection: some View {
        if !displayedPresets.isEmpty {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(displayedPresets) { preset in
                            Button {
                                fill(from: preset)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.foodName).fontWeight(.semibold)
                                    Text(preset.displayAmount).font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Fill (preset.foodName), (preset.displayAmount)")
                        }
                    }
                }
                Button("Manage Presets") { showingPresets = true }
            } header: { Text("Saved presets") }
        }
    }

    private var foodSection: some View {
        Section("What did \(childName) have?") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(foodSuggestions, id: \.self) { suggestion in
                        Button(suggestion) { foodName = suggestion }
                            .buttonStyle(.bordered)
                            .tint(foodName.caseInsensitiveCompare(suggestion) == .orderedSame ? Self.eventColor : .secondary)
                    }
                }
            }
            TextField("Food name", text: $foodName)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("food-name-field")
        }
    }

    private var amountSection: some View {
        Section("Amount consumed") {
            Picker("Unit", selection: $unit) {
                ForEach(FoodUnit.allCases, id: \.self) { Text($0.pickerTitle).tag($0) }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("food-unit-picker")

            if !FoodCatalog.quickAmounts(for: unit).isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(FoodCatalog.quickAmounts(for: unit), id: \.self) { amount in
                        Button(FoodEvent.formattedAmount(amount)) {
                            amountText = Self.editableAmount(amount)
                        }
                        .buttonStyle(.bordered)
                        .tint(Double(amountText) == amount ? Self.eventColor : .secondary)
                    }
                }
            }
            TextField("Amount", text: $amountText)
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("food-amount-field")
            if unit == .custom {
                TextField("Custom unit", text: $customUnitLabel)
                    .accessibilityIdentifier("food-custom-unit-field")
            }
        }
    }

    private var foodSuggestions: [String] {
        var seen = Set<String>()
        return (recentFoodNames + FoodCatalog.starterNames).filter { seen.insert($0.lowercased()).inserted }
    }

    private var effectiveName: String { foodName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var amount: Double? { Double(amountText.replacingOccurrences(of: ",", with: ".")) }

    private var validationMessage: String? {
        if effectiveName.isEmpty { return "Enter a food name." }
        guard let amount, amount.isFinite, amount > 0 else { return "Enter an amount greater than zero." }
        if unit == .custom, customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Enter a custom unit."
        }
        return nil
    }

    private var summarySentence: AttributedString {
        let timeStr = occurredAt.formatted(date: .omitted, time: .shortened)
        var s = summaryVariable(childName, color: Self.eventColor)
        s += AttributedString(" had ")

        if let amount, amount.isFinite, amount > 0 {
            let display = "\(FoodEvent.formattedAmount(amount)) \(unit.displayTitle(amount: amount, customLabel: customUnitLabel))"
            s += summaryVariable(display, color: Self.eventColor)
            s += AttributedString(" of ")
        }

        let name = effectiveName.isEmpty ? "food" : effectiveName
        s += summaryVariable(name, color: Self.eventColor)
        s += AttributedString(" at ")
        s += summaryVariable(timeStr, color: Self.eventColor)
        return s
    }

    private func fill(from preset: FoodPreset) {
        foodName = preset.foodName
        amountText = Self.editableAmount(preset.amount)
        unit = preset.unit
        customUnitLabel = preset.customUnitLabel ?? ""
    }

    private func save() {
        guard let amount, validationMessage == nil else { return }
        if saveAction(occurredAt, effectiveName, amount, unit, unit == .custom ? customUnitLabel : nil, saveAsPreset) {
            dismiss()
        }
    }

    private func updateDisplayedPreset(id: UUID, name: String, amount: Double, unit: FoodUnit, customLabel: String?) -> Bool {
        guard updatePreset(id, name, amount, unit, customLabel) else { return false }
        guard let index = displayedPresets.firstIndex(where: { $0.id == id }) else { return true }
        displayedPresets[index].foodName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        displayedPresets[index].amount = amount
        displayedPresets[index].unit = unit
        displayedPresets[index].customUnitLabel = unit == .custom ? customLabel : nil
        return true
    }

    private func deleteDisplayedPreset(id: UUID) -> Bool {
        guard deletePreset(id) else { return false }
        displayedPresets.removeAll { $0.id == id }
        return true
    }

    private func reorderDisplayedPresets(ids: [UUID]) -> Bool {
        guard reorderPresets(ids) else { return false }
        let byID = Dictionary(uniqueKeysWithValues: displayedPresets.map { ($0.id, $0) })
        displayedPresets = ids.compactMap { byID[$0] }
        return true
    }

    private static func editableAmount(_ amount: Double) -> String {
        amount == amount.rounded() ? String(Int(amount)) : String(amount)
    }
}

#Preview("Log food") {
    FoodEditorSheetView(
        navigationTitle: "Food",
        primaryActionTitle: "Save",
        childName: "Baby",
        recentFoodNames: ["Avocado"],
        presets: [],
        initialOccurredAt: .now,
        updatePreset: { _, _, _, _, _ in true },
        deletePreset: { _ in true },
        reorderPresets: { _ in true },
        saveAction: { _, _, _, _, _, _ in true }
    )
}
