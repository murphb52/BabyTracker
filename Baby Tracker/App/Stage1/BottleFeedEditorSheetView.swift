import BabyTrackerDomain
import SwiftUI

struct BottleFeedEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let saveAction: (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var amountMilliliters: String
    @State private var occurredAt: Date
    @State private var milkType: MilkTypeChoice

    init(
        navigationTitle: String,
        primaryActionTitle: String,
        initialAmountMilliliters: Int,
        initialOccurredAt: Date,
        initialMilkType: MilkType?,
        saveAction: @escaping (_ amountMilliliters: Int, _ occurredAt: Date, _ milkType: MilkType?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.saveAction = saveAction
        _amountMilliliters = State(initialValue: "\(initialAmountMilliliters)")
        _occurredAt = State(initialValue: initialOccurredAt)
        _milkType = State(initialValue: MilkTypeChoice(milkType: initialMilkType))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed") {
                    TextField("Amount (mL)", text: $amountMilliliters)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("bottle-feed-amount-field")

                    DatePicker(
                        "Time",
                        selection: $occurredAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("bottle-feed-time-picker")

                    Picker("Milk Type", selection: $milkType) {
                        ForEach(MilkTypeChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("bottle-feed-milk-type-picker")
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
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

    private var parsedAmountMilliliters: Int? {
        guard let amountValue = Int(amountMilliliters.trimmingCharacters(in: .whitespacesAndNewlines)),
              amountValue > 0 else {
            return nil
        }

        return amountValue
    }

    private var validationMessage: String? {
        guard !amountMilliliters.isEmpty, parsedAmountMilliliters == nil else {
            return nil
        }

        return "Enter an amount greater than 0 mL."
    }
}

extension BottleFeedEditorSheetView {
    private enum MilkTypeChoice: String, CaseIterable, Identifiable {
        case notSet
        case breastMilk
        case formula
        case mixed
        case other

        init(milkType: MilkType?) {
            switch milkType {
            case nil:
                self = .notSet
            case .breastMilk?:
                self = .breastMilk
            case .formula?:
                self = .formula
            case .mixed?:
                self = .mixed
            case .other?:
                self = .other
            }
        }

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .notSet:
                "Not Set"
            case .breastMilk:
                "Breast Milk"
            case .formula:
                "Formula"
            case .mixed:
                "Mixed"
            case .other:
                "Other"
            }
        }

        var value: MilkType? {
            switch self {
            case .notSet:
                nil
            case .breastMilk:
                .breastMilk
            case .formula:
                .formula
            case .mixed:
                .mixed
            case .other:
                .other
            }
        }
    }
}
