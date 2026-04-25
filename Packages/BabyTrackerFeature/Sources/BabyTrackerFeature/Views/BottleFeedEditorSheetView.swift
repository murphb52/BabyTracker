import BabyTrackerDomain
import SwiftUI

public struct BottleFeedEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .bottleFeed)
    private static let defaultQuickAmountsMilliliters = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120]

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let preferredVolumeUnit: FeedVolumeUnit
    let saveAction: (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool
    let deleteAction: (() -> Void)?
    let onSaveCustomAmounts: (([Int]) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var showDeleteConfirmation = false
    @State private var occurredAt: Date
    @State private var milkType: MilkTypeChoice
    @State private var showCustomAmount: Bool = false
    @State private var showAmountCustomizer: Bool = false
    @State private var customQuickAmounts: [Int]?
    private let smartSuggestions: [Int]
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    private let amountColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        preferredVolumeUnit: FeedVolumeUnit,
        initialAmountMilliliters: Int,
        initialOccurredAt: Date,
        initialMilkType: MilkType?,
        initialTimePreset: QuickTimeSelectorView.TimePreset = .now,
        showCustomAmountOnOpen: Bool = false,
        smartSuggestions: [Int] = [],
        customQuickAmountsMilliliters: [Int]? = nil,
        onSaveCustomAmounts: (([Int]) -> Void)? = nil,
        deleteAction: (() -> Void)? = nil,
        saveAction: @escaping (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.preferredVolumeUnit = preferredVolumeUnit
        self.deleteAction = deleteAction
        self.saveAction = saveAction
        self.onSaveCustomAmounts = onSaveCustomAmounts
        self.smartSuggestions = smartSuggestions
        _amountText = State(initialValue: Self.initialAmountText(
            for: initialAmountMilliliters,
            unit: preferredVolumeUnit
        ))
        _occurredAt = State(initialValue: initialOccurredAt)
        _milkType = State(initialValue: MilkTypeChoice(milkType: initialMilkType))
        _showCustomAmount = State(initialValue: showCustomAmountOnOpen)
        _customQuickAmounts = State(initialValue: customQuickAmountsMilliliters)
        self.initialTimePreset = initialTimePreset
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)

                Section("When was the feed?") {
                    QuickTimeSelectorView(selection: $occurredAt, initialPreset: initialTimePreset, buttonColor: Self.eventColor)
                        .accessibilityIdentifier("bottle-feed-time-selector")
                }

                Section("What milk?") {
                    milkTypeButtons
                }

                Section {
                    if !smartSuggestions.isEmpty {
                        suggestedAmountsRow
                    }

                    LazyVGrid(columns: amountColumns, spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                showCustomAmount = false
                                amountText = quickAmountDisplayText(for: amount)
                            } label: {
                                Text(FeedVolumeConverter.format(amountMilliliters: amount, in: preferredVolumeUnit))
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(!showCustomAmount && isSelected(amount: amount) ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                                    )
                                    .foregroundStyle(!showCustomAmount && isSelected(amount: amount) ? Color.white : Color.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("bottle-feed-amount-preset-\(amount)")
                        }

                        Button {
                            showCustomAmount = true
                            amountText = ""
                        } label: {
                            Text("Custom")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(showCustomAmount ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                                )
                                .foregroundStyle(showCustomAmount ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("bottle-feed-amount-custom")
                    }

                    if showCustomAmount {
                        TextField("Custom amount (\(preferredVolumeUnit.shortTitle))", text: $amountText)
                            .keyboardType(preferredVolumeUnit == .milliliters ? .numberPad : .decimalPad)
                            .accessibilityIdentifier("bottle-feed-amount-field")
                    }
                } header: {
                    amountSectionHeader
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if deleteAction != nil {
                    Section {
                        Button("Delete Bottle Feed", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("delete-bottle-feed-button")
                    }
                }
            }
            .sheet(isPresented: $showAmountCustomizer) {
                BottleAmountCustomizerView(
                    currentAmountsMilliliters: customQuickAmounts ?? Self.defaultQuickAmountsMilliliters,
                    preferredVolumeUnit: preferredVolumeUnit
                ) { newAmounts in
                    let resolved = newAmounts.isEmpty ? nil : newAmounts
                    customQuickAmounts = resolved
                    onSaveCustomAmounts?(resolved ?? [])
                }
            }
            .alert("Delete Bottle Feed?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteAction?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This event will be permanently removed.")
            }
            .tint(Self.eventColor)
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
                        guard let amountValue = parsedAmountMilliliters else {
                            return
                        }
                        let didSave = saveAction(amountValue, occurredAt, milkType.value)
                        if didSave {
                            dismiss()
                        }
                    }
                    .disabled(parsedAmountMilliliters == nil)
                    .accessibilityIdentifier("save-bottle-feed-button")
                }
            }
        }
    }

    private var amountSectionHeader: some View {
        HStack {
            Text("Amount")
            Spacer()
            if onSaveCustomAmounts != nil {
                Button {
                    showAmountCustomizer = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                }
                .textCase(nil)
                .accessibilityLabel("Customise amounts")
            }
        }
    }

    private var suggestedAmountsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggested")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(smartSuggestions, id: \.self) { amount in
                    Button {
                        showCustomAmount = false
                        amountText = quickAmountDisplayText(for: amount)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                            Text(FeedVolumeConverter.format(amountMilliliters: amount, in: preferredVolumeUnit))
                                .font(.subheadline.weight(.semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(!showCustomAmount && isSelected(amount: amount) ? Self.eventColor : Self.eventColor.opacity(0.12))
                        )
                        .foregroundStyle(!showCustomAmount && isSelected(amount: amount) ? Color.white : Self.eventColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var milkTypeButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                milkTypePill(.breastMilk)
                milkTypePill(.formula)
            }
            HStack(spacing: 8) {
                milkTypePill(.mixed)
                milkTypePill(.other)
                milkTypePill(.notSet)
            }
        }
    }

    private func milkTypePill(_ option: MilkTypeChoice) -> some View {
        Button {
            milkType = option
        } label: {
            Text(option.title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(milkType == option ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                )
                .foregroundStyle(milkType == option ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bottle-feed-milk-type-\(option.rawValue)")
    }

    private var parsedAmountMilliliters: Int? {
        let trimmedValue = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            return nil
        }

        switch preferredVolumeUnit {
        case .milliliters:
            guard let amountValue = Int(trimmedValue), amountValue > 0 else {
                return nil
            }
            return amountValue
        case .ounces:
            let normalized = trimmedValue.replacingOccurrences(of: ",", with: ".")
            guard let ounceValue = Double(normalized), ounceValue > 0 else {
                return nil
            }
            return FeedVolumeConverter.milliliters(from: ounceValue)
        }
    }

    private var validationMessage: String? {
        guard showCustomAmount, !amountText.isEmpty, parsedAmountMilliliters == nil else {
            return nil
        }
        return "Enter an amount greater than 0 \(preferredVolumeUnit.shortTitle)."
    }

    private func isSelected(amount: Int) -> Bool {
        parsedAmountMilliliters == amount
    }

    private var summarySentence: AttributedString {
        let timeStr = occurredAt.formatted(date: .omitted, time: .shortened)
        var s = summaryVariable(childName, color: Self.eventColor)
        guard let amount = parsedAmountMilliliters else {
            s += AttributedString(" had a bottle at ")
            s += summaryVariable(timeStr, color: Self.eventColor)
            return s
        }
        let amountStr = FeedVolumeConverter.format(amountMilliliters: amount, in: preferredVolumeUnit)
        s += AttributedString(" drank ")
        s += summaryVariable(amountStr, color: Self.eventColor)
        switch milkType {
        case .breastMilk:
            s += AttributedString(" of breast milk at ")
        case .formula:
            s += AttributedString(" of formula at ")
        case .mixed:
            s += AttributedString(" of mixed milk at ")
        case .notSet, .other:
            s += AttributedString(" at ")
        }
        s += summaryVariable(timeStr, color: Self.eventColor)
        return s
    }

    private var quickAmounts: [Int] {
        if let custom = customQuickAmounts, !custom.isEmpty {
            return custom
        }
        switch preferredVolumeUnit {
        case .milliliters:
            return Self.defaultQuickAmountsMilliliters
        case .ounces:
            return (1...8).map { FeedVolumeConverter.milliliters(from: Double($0)) }
        }
    }

    private func quickAmountDisplayText(for amountMilliliters: Int) -> String {
        switch preferredVolumeUnit {
        case .milliliters:
            return "\(amountMilliliters)"
        case .ounces:
            return FeedVolumeConverter.ounces(from: amountMilliliters).formatted(
                .number
                    .precision(.fractionLength(0...1))
                    .rounded(rule: .toNearestOrAwayFromZero, increment: 0.1)
            )
        }
    }

    private static func initialAmountText(
        for amountMilliliters: Int,
        unit: FeedVolumeUnit
    ) -> String {
        guard amountMilliliters > 0 else {
            return ""
        }

        switch unit {
        case .milliliters:
            return "\(amountMilliliters)"
        case .ounces:
            return FeedVolumeConverter.ounces(from: amountMilliliters).formatted(
                .number
                    .precision(.fractionLength(0...1))
                    .rounded(rule: .toNearestOrAwayFromZero, increment: 0.1)
            )
        }
    }
}

extension BottleFeedEditorSheetView {
    enum MilkTypeChoice: String, CaseIterable, Identifiable {
        case notSet
        case breastMilk
        case formula
        case mixed
        case other

        init(milkType: MilkType?) {
            switch milkType {
            case nil: self = .notSet
            case .breastMilk?: self = .breastMilk
            case .formula?: self = .formula
            case .mixed?: self = .mixed
            case .other?: self = .other
            }
        }

        var id: String { rawValue }

        var title: String {
            switch self {
            case .notSet: "Not Set"
            case .breastMilk: "Breast Milk"
            case .formula: "Formula"
            case .mixed: "Mixed"
            case .other: "Other"
            }
        }

        var value: MilkType? {
            switch self {
            case .notSet: nil
            case .breastMilk: .breastMilk
            case .formula: .formula
            case .mixed: .mixed
            case .other: .other
            }
        }
    }
}

#Preview("Default amounts") {
    BottleFeedEditorSheetView(
        navigationTitle: "Bottle Feed",
        primaryActionTitle: "Save",
        childName: "Robyn",
        preferredVolumeUnit: .milliliters,
        initialAmountMilliliters: 0,
        initialOccurredAt: Date(),
        initialMilkType: nil
    ) { _, _, _ in true }
}

#Preview("With smart suggestions") {
    BottleFeedEditorSheetView(
        navigationTitle: "Bottle Feed",
        primaryActionTitle: "Save",
        childName: "Robyn",
        preferredVolumeUnit: .milliliters,
        initialAmountMilliliters: 0,
        initialOccurredAt: Date(),
        initialMilkType: nil,
        smartSuggestions: [120, 90],
        onSaveCustomAmounts: { _ in }
    ) { _, _, _ in true }
}

#Preview("Custom amounts") {
    BottleFeedEditorSheetView(
        navigationTitle: "Bottle Feed",
        primaryActionTitle: "Save",
        childName: "Robyn",
        preferredVolumeUnit: .milliliters,
        initialAmountMilliliters: 0,
        initialOccurredAt: Date(),
        initialMilkType: nil,
        customQuickAmountsMilliliters: [60, 90, 120, 150, 180],
        onSaveCustomAmounts: { _ in }
    ) { _, _, _ in true }
}
