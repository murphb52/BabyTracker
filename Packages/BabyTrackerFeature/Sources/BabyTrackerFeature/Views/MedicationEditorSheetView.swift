import BabyTrackerDomain
import SwiftUI

public struct MedicationEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .medication)

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let recentMedicineNames: [String]
    let millilitreAmounts: [Double]
    let saveAction: (_ occurredAt: Date, _ medicineName: String, _ amount: Double, _ unit: MedicationUnit, _ customUnitLabel: String?) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var occurredAt: Date
    @State private var medicineName: String
    @State private var amountText: String
    @State private var unit: MedicationUnit
    @State private var customUnitLabel: String
    @State private var showDeleteConfirmation = false
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    private let amountColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        recentMedicineNames: [String],
        millilitreAmounts: [Double],
        initialOccurredAt: Date,
        initialMedicineName: String = "",
        initialAmount: Double? = nil,
        initialUnit: MedicationUnit = .ml,
        initialCustomUnitLabel: String? = nil,
        initialTimePreset: QuickTimeSelectorView.TimePreset = .now,
        deleteAction: (() -> Void)? = nil,
        saveAction: @escaping (_ occurredAt: Date, _ medicineName: String, _ amount: Double, _ unit: MedicationUnit, _ customUnitLabel: String?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.recentMedicineNames = recentMedicineNames
        self.millilitreAmounts = millilitreAmounts
        self.deleteAction = deleteAction
        self.saveAction = saveAction
        _occurredAt = State(initialValue: initialOccurredAt)
        _medicineName = State(initialValue: initialMedicineName)
        _amountText = State(initialValue: initialAmount.map(Self.amountText(for:)) ?? "")
        _unit = State(initialValue: initialUnit)
        _customUnitLabel = State(initialValue: initialCustomUnitLabel ?? "")
        self.initialTimePreset = initialTimePreset
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)

                Section("Which medicine?") {
                    if !medicineSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(medicineSuggestions, id: \.self) { name in
                                    Button {
                                        medicineName = name
                                    } label: {
                                        Text(name)
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelectedName(name) ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                                            )
                                            .foregroundStyle(isSelectedName(name) ? Color.white : Color.primary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("medication-name-suggestion-\(name)")
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }

                    TextField("Medicine name", text: $medicineName)
                        .accessibilityIdentifier("medication-name-field")
                }

                Section("How much?") {
                    unitPicker

                    if !amountPresets.isEmpty {
                        LazyVGrid(columns: amountColumns, spacing: 8) {
                            ForEach(amountPresets, id: \.self) { amount in
                                Button {
                                    amountText = Self.amountText(for: amount)
                                } label: {
                                    Text(Self.amountText(for: amount))
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(isSelectedAmount(amount) ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                                        )
                                        .foregroundStyle(isSelectedAmount(amount) ? Color.white : Color.primary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("medication-amount-preset-\(Self.amountText(for: amount))")
                            }
                        }
                    }

                    HStack {
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("medication-amount-field")
                        Text(unitDisplay)
                            .foregroundStyle(.secondary)
                    }

                    if unit == .custom {
                        TextField("Unit (e.g. puff, sachet)", text: $customUnitLabel)
                            .accessibilityIdentifier("medication-custom-unit-field")
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("When?") {
                    QuickTimeSelectorView(selection: $occurredAt, initialPreset: initialTimePreset, buttonColor: Self.eventColor)
                        .accessibilityIdentifier("medication-time-selector")
                }

                if deleteAction != nil {
                    Section {
                        Button("Delete Medication", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("delete-medication-button")
                    }
                }
            }
            .alert("Delete Medication?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAction?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This event will be permanently removed.")
            }
            .scrollContentBackground(.hidden)
            .background(Self.eventColor.opacity(0.08))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) {
                        guard let amount = parsedAmount, isValid else { return }
                        let didSave = saveAction(
                            occurredAt,
                            medicineName.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount,
                            unit,
                            unit == .custom ? customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil
                        )
                        if didSave {
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save-medication-button")
                }
            }
        }
        .tint(Self.eventColor)
    }

    private var unitPicker: some View {
        Picker("Unit", selection: $unit) {
            ForEach(MedicationUnit.allCases, id: \.self) { unit in
                Text(unitLabel(for: unit)).tag(unit)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("medication-unit-picker")
    }

    private func unitLabel(for unit: MedicationUnit) -> String {
        switch unit {
        case .ml: "ml"
        case .mg: "mg"
        case .drops: "drops"
        case .tablet: "tablet"
        case .custom: "custom"
        }
    }

    private var unitDisplay: String {
        if unit == .custom {
            let trimmed = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "unit" : trimmed
        }
        return unit.shortTitle
    }

    /// Quick-pick names: previously logged medicines first, then seeded catalog entries
    /// not already present (case-insensitive).
    private var medicineSuggestions: [String] {
        var seen = Set(recentMedicineNames.map { $0.lowercased() })
        var names = recentMedicineNames
        for name in MedicationCatalog.commonMedicines where seen.insert(name.lowercased()).inserted {
            names.append(name)
        }
        return names
    }

    private var amountPresets: [Double] {
        switch unit {
        case .ml:
            return millilitreAmounts
        case .tablet:
            return [0.5, 1, 2]
        case .drops:
            return [1, 2, 3, 5]
        case .mg, .custom:
            return []
        }
    }

    private var parsedAmount: Double? {
        Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    private var isValid: Bool {
        guard !medicineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount = parsedAmount, amount > 0 else { return false }
        if unit == .custom, customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }

    private var validationMessage: String? {
        guard !amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        guard let amount = parsedAmount, amount > 0 else {
            return "Enter an amount greater than zero."
        }
        return nil
    }

    private func isSelectedName(_ name: String) -> Bool {
        medicineName.caseInsensitiveCompare(name) == .orderedSame
    }

    private func isSelectedAmount(_ amount: Double) -> Bool {
        parsedAmount == amount
    }

    private var summarySentence: AttributedString {
        let timeText = occurredAt.formatted(date: .omitted, time: .shortened)
        var sentence = summaryVariable(childName, color: Self.eventColor)
        sentence += AttributedString(" had ")

        let name = medicineName.trimmingCharacters(in: .whitespacesAndNewlines)
        sentence += summaryVariable(name.isEmpty ? "medicine" : name, color: Self.eventColor)

        if let amount = parsedAmount, amount > 0 {
            sentence += AttributedString(" (")
            sentence += summaryVariable("\(Self.amountText(for: amount)) \(unitDisplay)", color: Self.eventColor)
            sentence += AttributedString(")")
        }

        sentence += AttributedString(" at ")
        sentence += summaryVariable(timeText, color: Self.eventColor)
        return sentence
    }

    private static func amountText(for amount: Double) -> String {
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}

#Preview("Quick Log Medication") {
    MedicationEditorSheetView(
        navigationTitle: "Medication",
        primaryActionTitle: "Save",
        childName: "Poppy",
        recentMedicineNames: ["Paracetamol (Calpol)"],
        millilitreAmounts: [2.5, 5, 7.5, 10],
        initialOccurredAt: .now,
        saveAction: { _, _, _, _, _ in true }
    )
}
