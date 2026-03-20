import BabyTrackerDomain
import SwiftUI

struct NappyEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let saveAction: (_ type: NappyType, _ occurredAt: Date, _ intensity: NappyIntensity?, _ pooColor: PooColor?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var type: NappyTypeChoice
    @State private var occurredAt: Date
    @State private var intensity: NappyIntensityChoice
    @State private var pooColor: PooColorChoice

    init(
        navigationTitle: String,
        primaryActionTitle: String,
        initialType: NappyType,
        initialOccurredAt: Date,
        initialIntensity: NappyIntensity?,
        initialPooColor: PooColor?,
        saveAction: @escaping (_ type: NappyType, _ occurredAt: Date, _ intensity: NappyIntensity?, _ pooColor: PooColor?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.saveAction = saveAction
        _type = State(initialValue: NappyTypeChoice(type: initialType))
        _occurredAt = State(initialValue: initialOccurredAt)
        _intensity = State(initialValue: NappyIntensityChoice(intensity: initialIntensity))
        _pooColor = State(initialValue: PooColorChoice(color: initialPooColor))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Nappy") {
                    Picker("Type", selection: $type) {
                        ForEach(NappyTypeChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("nappy-type-picker")

                    DatePicker(
                        "Time",
                        selection: $occurredAt,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("nappy-time-picker")

                    Picker("Intensity", selection: $intensity) {
                        ForEach(NappyIntensityChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("nappy-intensity-picker")

                    if supportsPooColor {
                        Picker("Poo Color", selection: $pooColor) {
                            ForEach(PooColorChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("nappy-poo-color-picker")
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium])
            .onChange(of: type) { _, newType in
                guard !NappyEntry.supportsPooColor(for: newType.value) else {
                    return
                }

                pooColor = .notSet
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) {
                        let didSave = saveAction(
                            type.value,
                            occurredAt,
                            intensity.value,
                            supportsPooColor ? pooColor.value : nil
                        )
                        if didSave {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("save-nappy-button")
                }
            }
        }
    }

    private var supportsPooColor: Bool {
        NappyEntry.supportsPooColor(for: type.value)
    }
}

extension NappyEditorSheetView {
    private enum NappyTypeChoice: String, CaseIterable, Identifiable {
        case dry
        case wee
        case poo
        case mixed

        init(type: NappyType) {
            self = NappyTypeChoice(rawValue: type.rawValue) ?? .dry
        }

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .dry:
                "Dry"
            case .wee:
                "Wee"
            case .poo:
                "Poo"
            case .mixed:
                "Mixed"
            }
        }

        var value: NappyType {
            NappyType(rawValue: rawValue) ?? .dry
        }
    }

    private enum NappyIntensityChoice: String, CaseIterable, Identifiable {
        case notSet
        case low
        case medium
        case high

        init(intensity: NappyIntensity?) {
            switch intensity {
            case nil:
                self = .notSet
            case .low?:
                self = .low
            case .medium?:
                self = .medium
            case .high?:
                self = .high
            }
        }

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .notSet:
                "Not Set"
            case .low:
                "Low"
            case .medium:
                "Medium"
            case .high:
                "High"
            }
        }

        var value: NappyIntensity? {
            switch self {
            case .notSet:
                nil
            case .low:
                .low
            case .medium:
                .medium
            case .high:
                .high
            }
        }
    }

    private enum PooColorChoice: String, CaseIterable, Identifiable {
        case notSet
        case yellow
        case mustard
        case brown
        case green
        case black
        case other

        init(color: PooColor?) {
            switch color {
            case nil:
                self = .notSet
            case .yellow?:
                self = .yellow
            case .mustard?:
                self = .mustard
            case .brown?:
                self = .brown
            case .green?:
                self = .green
            case .black?:
                self = .black
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
            case .yellow:
                "Yellow"
            case .mustard:
                "Mustard"
            case .brown:
                "Brown"
            case .green:
                "Green"
            case .black:
                "Black"
            case .other:
                "Other"
            }
        }

        var value: PooColor? {
            switch self {
            case .notSet:
                nil
            case .yellow:
                .yellow
            case .mustard:
                .mustard
            case .brown:
                .brown
            case .green:
                .green
            case .black:
                .black
            case .other:
                .other
            }
        }
    }
}
