import BabyTrackerDomain
import SwiftUI

public struct MedicationEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .medication)

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let recentMedicineNames: [String]
    let millilitreAmounts: [Double]
    let reminderPreferenceLoader: ((_ medicineName: String) -> MedicationReminderPreference?)?
    let saveAction: (_ occurredAt: Date, _ medicineName: String, _ amount: Double, _ unit: MedicationUnit, _ customUnitLabel: String?, _ reminder: MedicationReminderPreference?) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var occurredAt: Date
    @State private var medicineName: String
    @State private var isCustomMedicine: Bool
    @State private var customMedicineName: String
    @State private var amountText: String
    @State private var unit: MedicationUnit
    @State private var customUnitLabel: String
    @State private var showDeleteConfirmation = false
    @State private var isReminderEnabled = false
    @State private var reminderIntervalHours: Int = 4
    @State private var reminderMode: ReminderMode = .safeToGive
    @State private var reminderReferencePoint: ReminderReferencePoint = .doseTime
    @State private var isCustomInterval = false
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    private static let quickIntervalOptions: [Int] = [2, 4, 6, 8]

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
        reminderPreferenceLoader: ((_ medicineName: String) -> MedicationReminderPreference?)? = nil,
        deleteAction: (() -> Void)? = nil,
        saveAction: @escaping (_ occurredAt: Date, _ medicineName: String, _ amount: Double, _ unit: MedicationUnit, _ customUnitLabel: String?, _ reminder: MedicationReminderPreference?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.recentMedicineNames = recentMedicineNames
        self.millilitreAmounts = millilitreAmounts
        self.reminderPreferenceLoader = reminderPreferenceLoader
        self.deleteAction = deleteAction
        self.saveAction = saveAction
        let allKnownNames = Set(
            (recentMedicineNames + MedicationCatalog.commonMedicines).map { $0.lowercased() }
        )
        let isCustom = !initialMedicineName.isEmpty && !allKnownNames.contains(initialMedicineName.lowercased())
        _occurredAt = State(initialValue: initialOccurredAt)
        _medicineName = State(initialValue: isCustom ? "" : initialMedicineName)
        _isCustomMedicine = State(initialValue: isCustom)
        _customMedicineName = State(initialValue: isCustom ? initialMedicineName : "")
        _amountText = State(initialValue: initialAmount.map(Self.amountText(for:)) ?? "")
        _unit = State(initialValue: initialUnit)
        _customUnitLabel = State(initialValue: initialCustomUnitLabel ?? "")
        self.initialTimePreset = initialTimePreset
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)
                medicineSection
                amountSection
                validationSection
                whenSection
                reminderSection
                deleteSection
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
            .toolbar { toolbarContent }
        }
        .tint(Self.eventColor)
    }

    @ViewBuilder
    private var medicineSection: some View {
        Section {
            medicineSuggestionsRow
            if isCustomMedicine {
                TextField("Medicine name", text: $customMedicineName)
                    .accessibilityIdentifier("medication-name-field")
            }
        } header: {
            Text("Which medicine?")
        }
    }

    private var medicineSuggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(medicineSuggestions, id: \.self) { name in
                    Button {
                        medicineName = name
                        isCustomMedicine = false
                        prefillReminderIfAvailable(for: name)
                    } label: {
                        chipLabel(name, isSelected: !isCustomMedicine && isSelectedName(name), shape: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("medication-name-suggestion-\(name)")
                }
                Button {
                    isCustomMedicine = true
                    medicineName = ""
                } label: {
                    chipLabel("Custom", isSelected: isCustomMedicine, shape: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("medication-name-custom")
            }
            .padding(.vertical, 2)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
    }

    @ViewBuilder
    private var amountSection: some View {
        Section("How much?") {
            unitPicker

            if !amountPresets.isEmpty {
                amountPresetGrid
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
    }

    private var amountPresetGrid: some View {
        LazyVGrid(columns: amountColumns, spacing: 8) {
            ForEach(amountPresets, id: \.self) { amount in
                Button {
                    amountText = Self.amountText(for: amount)
                } label: {
                    chipLabel(
                        Self.amountText(for: amount),
                        isSelected: isSelectedAmount(amount),
                        shape: RoundedRectangle(cornerRadius: 12, style: .continuous),
                        fillWidth: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("medication-amount-preset-\(Self.amountText(for: amount))")
            }
        }
    }

    private func chipLabel(
        _ text: String,
        isSelected: Bool,
        shape: some Shape,
        fillWidth: Bool = false
    ) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: fillWidth ? .infinity : nil)
            .padding(.horizontal, fillWidth ? 0 : 14)
            .padding(.vertical, fillWidth ? 10 : 8)
            .background(shape.fill(isSelected ? Self.eventColor : Color(.tertiarySystemGroupedBackground)))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
    }

    @ViewBuilder
    private var validationSection: some View {
        if let validationMessage {
            Section {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }
        }
    }

    private var whenSection: some View {
        Section("When?") {
            QuickTimeSelectorView(selection: $occurredAt, initialPreset: initialTimePreset, buttonColor: Self.eventColor)
                .accessibilityIdentifier("medication-time-selector")
        }
    }

    @ViewBuilder
    private var reminderSection: some View {
        Section {
            Toggle("Set a reminder", isOn: $isReminderEnabled)
                .accessibilityIdentifier("medication-reminder-toggle")
                .onChange(of: isReminderEnabled) { _, newValue in
                    if newValue {
                        prefillReminderIfAvailable(for: effectiveMedicineName)
                    }
                }

            if isReminderEnabled {
                reminderIntervalRow
                reminderModeRow
                reminderReferencePointRow
                if let fireDate = calculatedFireDate {
                    HStack {
                        Text("Reminder will fire at")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(fireDate, style: .time)
                            .foregroundStyle(Self.eventColor)
                            .fontWeight(.semibold)
                    }
                    .accessibilityIdentifier("medication-reminder-fire-time")
                }
            }
        } header: {
            Text("Reminder")
        }
    }

    private var reminderIntervalRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How long after the dose?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.quickIntervalOptions, id: \.self) { hours in
                        Button {
                            reminderIntervalHours = hours
                            isCustomInterval = false
                        } label: {
                            chipLabel(
                                "\(hours)h",
                                isSelected: !isCustomInterval && reminderIntervalHours == hours,
                                shape: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("medication-reminder-interval-\(hours)h")
                    }
                    Button {
                        isCustomInterval = true
                    } label: {
                        chipLabel("Custom", isSelected: isCustomInterval, shape: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("medication-reminder-interval-custom")
                }
                .padding(.vertical, 2)
            }
            if isCustomInterval {
                Stepper("\(reminderIntervalHours) hour\(reminderIntervalHours == 1 ? "" : "s")", value: $reminderIntervalHours, in: 1...24)
                    .accessibilityIdentifier("medication-reminder-custom-stepper")
            }
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
    }

    private var reminderModeRow: some View {
        Picker("Notification type", selection: $reminderMode) {
            Text("Safe to give again").tag(ReminderMode.safeToGive)
            Text("Next dose due").tag(ReminderMode.nextDueDose)
        }
        .accessibilityIdentifier("medication-reminder-mode-picker")
    }

    private var reminderReferencePointRow: some View {
        Picker("Count from", selection: $reminderReferencePoint) {
            Text("Dose time").tag(ReminderReferencePoint.doseTime)
            Text("Now").tag(ReminderReferencePoint.now)
        }
        .accessibilityIdentifier("medication-reminder-reference-picker")
    }

    @ViewBuilder
    private var deleteSection: some View {
        if deleteAction != nil {
            Section {
                Button("Delete Medication", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .accessibilityIdentifier("delete-medication-button")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(primaryActionTitle) {
                guard let amount = parsedAmount, isValid else { return }
                let reminder = isReminderEnabled ? MedicationReminderPreference(
                    intervalHours: reminderIntervalHours,
                    mode: reminderMode,
                    referencePoint: reminderReferencePoint
                ) : nil
                let didSave = saveAction(
                    occurredAt,
                    effectiveMedicineName.trimmingCharacters(in: .whitespacesAndNewlines),
                    amount,
                    unit,
                    unit == .custom ? customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
                    reminder
                )
                if didSave {
                    dismiss()
                }
            }
            .disabled(!isValid)
            .accessibilityIdentifier("save-medication-button")
        }
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

    private var calculatedFireDate: Date? {
        guard isReminderEnabled else { return nil }
        let reference = reminderReferencePoint == .doseTime ? occurredAt : Date.now
        let fireDate = reference.addingTimeInterval(TimeInterval(reminderIntervalHours) * 3_600)
        return fireDate > Date.now ? fireDate : nil
    }

    private func prefillReminderIfAvailable(for name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let preference = reminderPreferenceLoader?(trimmed) else { return }
        reminderIntervalHours = preference.intervalHours
        reminderMode = preference.mode
        reminderReferencePoint = preference.referencePoint
        isCustomInterval = !Self.quickIntervalOptions.contains(preference.intervalHours)
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

    private var effectiveMedicineName: String {
        isCustomMedicine ? customMedicineName : medicineName
    }

    private var isValid: Bool {
        guard !effectiveMedicineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
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

        let name = effectiveMedicineName.trimmingCharacters(in: .whitespacesAndNewlines)
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
        saveAction: { _, _, _, _, _, _ in true }
    )
}

#Preview("Reminder Pre-filled") {
    MedicationEditorSheetView(
        navigationTitle: "Medication",
        primaryActionTitle: "Save",
        childName: "Poppy",
        recentMedicineNames: ["Paracetamol (Calpol)"],
        millilitreAmounts: [2.5, 5, 7.5, 10],
        initialOccurredAt: .now,
        reminderPreferenceLoader: { _ in
            MedicationReminderPreference(intervalHours: 4, mode: .safeToGive, referencePoint: .doseTime)
        },
        saveAction: { _, _, _, _, _, _ in true }
    )
}
