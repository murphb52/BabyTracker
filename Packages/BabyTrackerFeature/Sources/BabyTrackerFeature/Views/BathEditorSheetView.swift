import BabyTrackerDomain
import SwiftUI

public struct BathEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .bath)

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let saveAction: (_ occurredAt: Date, _ usedShampoo: Bool, _ usedSoap: Bool) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var occurredAt: Date
    @State private var usedShampoo: Bool
    @State private var usedSoap: Bool
    @State private var showDeleteConfirmation = false
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        initialOccurredAt: Date,
        initialUsedShampoo: Bool,
        initialUsedSoap: Bool,
        initialTimePreset: QuickTimeSelectorView.TimePreset = .now,
        deleteAction: (() -> Void)? = nil,
        saveAction: @escaping (_ occurredAt: Date, _ usedShampoo: Bool, _ usedSoap: Bool) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.deleteAction = deleteAction
        self.saveAction = saveAction
        _occurredAt = State(initialValue: initialOccurredAt)
        _usedShampoo = State(initialValue: initialUsedShampoo)
        _usedSoap = State(initialValue: initialUsedSoap)
        self.initialTimePreset = initialTimePreset
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)

                Section("When was the Bath?") {
                    QuickTimeSelectorView(selection: $occurredAt, initialPreset: initialTimePreset, buttonColor: Self.eventColor)
                        .accessibilityIdentifier("bath-time-selector")
                }

                Section("Used") {
                    Toggle("Shampoo", isOn: $usedShampoo)
                        .accessibilityIdentifier("bath-shampoo-toggle")
                    Toggle("Soap", isOn: $usedSoap)
                        .accessibilityIdentifier("bath-soap-toggle")
                }

                if deleteAction != nil {
                    Section {
                        Button("Delete Bath", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("delete-bath-button")
                    }
                }
            }
            .alert("Delete Bath?", isPresented: $showDeleteConfirmation) {
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
                        let didSave = saveAction(occurredAt, usedShampoo, usedSoap)
                        if didSave {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("save-bath-button")
                }
            }
        }
        .tint(Self.eventColor)
    }

    private var summarySentence: AttributedString {
        let timeText = occurredAt.formatted(date: .omitted, time: .shortened)
        var sentence = summaryVariable(childName, color: Self.eventColor)
        sentence += AttributedString(" had a bath at ")
        sentence += summaryVariable(timeText, color: Self.eventColor)

        let bathDetails = selectedDetailTitles
        if !bathDetails.isEmpty {
            sentence += AttributedString(" using ")
            sentence += summaryVariable(bathDetails.joined(separator: " and ").lowercased(), color: Self.eventColor)
        }

        return sentence
    }

    private var selectedDetailTitles: [String] {
        var details: [String] = []
        if usedShampoo {
            details.append("Shampoo")
        }
        if usedSoap {
            details.append("Soap")
        }
        return details
    }
}

#Preview("Quick Log Bath") {
    BathEditorSheetView(
        navigationTitle: "Bath",
        primaryActionTitle: "Save",
        childName: "Poppy",
        initialOccurredAt: .now,
        initialUsedShampoo: true,
        initialUsedSoap: false,
        saveAction: { _, _, _ in true }
    )
}

#Preview("Edit Bath") {
    BathEditorSheetView(
        navigationTitle: "Edit Bath",
        primaryActionTitle: "Update",
        childName: "Poppy",
        initialOccurredAt: .now.addingTimeInterval(-3_600),
        initialUsedShampoo: true,
        initialUsedSoap: true,
        initialTimePreset: .custom,
        deleteAction: {},
        saveAction: { _, _, _ in true }
    )
}
