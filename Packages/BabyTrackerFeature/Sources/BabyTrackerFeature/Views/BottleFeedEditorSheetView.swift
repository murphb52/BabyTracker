import BabyTrackerDomain
import SwiftUI

public struct BottleFeedEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let saveAction: (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var amountMilliliters: String
    @State private var occurredAt: Date
    @State private var milkType: MilkTypeChoice
    @State private var showCustomAmount: Bool = false

    private let quickAmounts = [30, 60, 90, 120, 150, 180, 210, 240]

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
        initialAmountMilliliters: Int,
        initialOccurredAt: Date,
        initialMilkType: MilkType?,
        saveAction: @escaping (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.saveAction = saveAction
        _amountMilliliters = State(initialValue: initialAmountMilliliters > 0 ? "\(initialAmountMilliliters)" : "")
        _occurredAt = State(initialValue: initialOccurredAt)
        _milkType = State(initialValue: MilkTypeChoice(milkType: initialMilkType))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("When was the feed?") {
                    QuickTimeSelectorView(selection: $occurredAt)
                        .accessibilityIdentifier("bottle-feed-time-selector")
                }

                Section("What milk?") {
                    milkTypeButtons
                }

                Section("Amount") {
                    LazyVGrid(columns: amountColumns, spacing: 8) {
                        ForEach(quickAmounts, id: \.self) { amount in
                            Button {
                                showCustomAmount = false
                                amountMilliliters = "\(amount)"
                            } label: {
                                Text("\(amount) mL")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(!showCustomAmount && isSelected(amount: amount) ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                    )
                                    .foregroundStyle(!showCustomAmount && isSelected(amount: amount) ? Color.white : Color.primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("bottle-feed-amount-preset-\(amount)")
                        }

                        Button {
                            showCustomAmount = true
                            amountMilliliters = ""
                        } label: {
                            Text("Custom")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(showCustomAmount ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                                )
                                .foregroundStyle(showCustomAmount ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("bottle-feed-amount-custom")
                    }

                    if showCustomAmount {
                        TextField("Custom amount (mL)", text: $amountMilliliters)
                            .keyboardType(.numberPad)
                            .accessibilityIdentifier("bottle-feed-amount-field")
                    }
                }

                LoggingSummaryView(sentence: summarySentence)

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
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
                        .fill(milkType == option ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(milkType == option ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("bottle-feed-milk-type-\(option.rawValue)")
    }

    private var parsedAmountMilliliters: Int? {
        guard let amountValue = Int(amountMilliliters.trimmingCharacters(in: .whitespacesAndNewlines)),
              amountValue > 0 else {
            return nil
        }
        return amountValue
    }

    private var validationMessage: String? {
        guard showCustomAmount, !amountMilliliters.isEmpty, parsedAmountMilliliters == nil else {
            return nil
        }
        return "Enter an amount greater than 0 mL."
    }

    private func isSelected(amount: Int) -> Bool {
        parsedAmountMilliliters == amount
    }

    private var summarySentence: AttributedString {
        let timeStr = occurredAt.formatted(date: .omitted, time: .shortened)
        var s = summaryVariable(childName)
        guard let amount = parsedAmountMilliliters else {
            s += AttributedString(" had a bottle at ")
            s += summaryVariable(timeStr)
            return s
        }
        let amountStr = "\(amount) mL"
        s += AttributedString(" drank ")
        s += summaryVariable(amountStr)
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
        s += summaryVariable(timeStr)
        return s
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

#Preview {
    BottleFeedEditorSheetView(
        navigationTitle: "Bottle Feed",
        primaryActionTitle: "Save",
        childName: "Robyn",
        initialAmountMilliliters: 0,
        initialOccurredAt: Date(),
        initialMilkType: nil
    ) { _, _, _ in true }
}
