import BabyTrackerDomain
import SwiftUI

struct BottleAmountCustomizerView: View {
    let preferredVolumeUnit: FeedVolumeUnit
    let onSave: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amounts: [Int]
    @State private var newAmountText: String = ""
    @State private var showDuplicateWarning = false

    init(
        currentAmountsMilliliters: [Int],
        preferredVolumeUnit: FeedVolumeUnit,
        onSave: @escaping ([Int]) -> Void
    ) {
        self.preferredVolumeUnit = preferredVolumeUnit
        self.onSave = onSave
        _amounts = State(initialValue: currentAmountsMilliliters.sorted())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if amounts.isEmpty {
                        Text("No custom amounts. Add some below.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(amounts, id: \.self) { amount in
                            HStack {
                                Text(FeedVolumeConverter.format(amountMilliliters: amount, in: preferredVolumeUnit))
                                Spacer()
                                Button(role: .destructive) {
                                    removeAmount(amount)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                } header: {
                    Text("Quick Amounts")
                } footer: {
                    Text("These replace the default quick-select buttons in the bottle picker.")
                }

                Section("Add Amount") {
                    HStack {
                        TextField(
                            preferredVolumeUnit == .milliliters ? "e.g. 150" : "e.g. 5",
                            text: $newAmountText
                        )
                        .keyboardType(preferredVolumeUnit == .milliliters ? .numberPad : .decimalPad)

                        Button("Add") {
                            addAmount()
                        }
                        .disabled(parsedNewAmountMilliliters == nil)
                    }

                    if showDuplicateWarning {
                        Text("That amount is already in the list.")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        onSave([])
                        dismiss()
                    }
                } footer: {
                    Text("Resetting removes your customisation and restores the original quick amounts.")
                }
            }
            .navigationTitle("Customise Amounts")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.snappy(duration: 0.2), value: amounts)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(amounts)
                        dismiss()
                    }
                    .disabled(amounts.isEmpty)
                }
            }
        }
    }

    private var parsedNewAmountMilliliters: Int? {
        let trimmed = newAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        switch preferredVolumeUnit {
        case .milliliters:
            guard let value = Int(trimmed), value > 0 else { return nil }
            return value
        case .ounces:
            let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
            guard let oz = Double(normalized), oz > 0 else { return nil }
            return FeedVolumeConverter.milliliters(from: oz)
        }
    }

    private func addAmount() {
        guard let ml = parsedNewAmountMilliliters else { return }
        if amounts.contains(ml) {
            showDuplicateWarning = true
            return
        }
        showDuplicateWarning = false
        withAnimation(.snappy(duration: 0.2)) {
            amounts.append(ml)
            amounts.sort()
        }
        newAmountText = ""
    }

    private func removeAmount(_ amount: Int) {
        withAnimation(.snappy(duration: 0.2)) {
            amounts.removeAll { $0 == amount }
        }
    }
}

#Preview {
    BottleAmountCustomizerView(
        currentAmountsMilliliters: [60, 90, 120, 150, 180],
        preferredVolumeUnit: .milliliters,
        onSave: { _ in }
    )
}
