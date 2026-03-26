import BabyTrackerDomain
import SwiftUI

public struct NappyEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .nappy)

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let saveAction: (_ type: NappyType, _ occurredAt: Date, _ peeVolume: NappyVolume?, _ pooVolume: NappyVolume?, _ pooColor: PooColor?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var type: NappyTypeChoice
    @State private var occurredAt: Date
    @State private var peeVolume: NappyVolumeChoice
    @State private var pooVolume: NappyVolumeChoice
    @State private var pooColor: PooColorChoice

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        initialType: NappyType,
        initialOccurredAt: Date,
        initialPeeVolume: NappyVolume?,
        initialPooVolume: NappyVolume?,
        initialPooColor: PooColor?,
        saveAction: @escaping (_ type: NappyType, _ occurredAt: Date, _ peeVolume: NappyVolume?, _ pooVolume: NappyVolume?, _ pooColor: PooColor?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.saveAction = saveAction
        _type = State(initialValue: NappyTypeChoice(type: initialType))
        _occurredAt = State(initialValue: initialOccurredAt)
        _peeVolume = State(initialValue: NappyVolumeChoice(volume: initialPeeVolume))
        _pooVolume = State(initialValue: NappyVolumeChoice(volume: initialPooVolume))
        _pooColor = State(initialValue: PooColorChoice(color: initialPooColor))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("When was the Nappy?") {
                    QuickTimeSelectorView(selection: $occurredAt)
                        .accessibilityIdentifier("nappy-time-selector")
                }

                Section("Type") {
                    typeSelectorButtons
                }

                if supportsPeeVolume {
                    Section("Pee Volume") {
                        Picker("Pee Volume", selection: $peeVolume) {
                            ForEach(NappyVolumeChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("nappy-pee-volume-picker")
                    }
                }

                if supportsPooVolume {
                    Section("Poo Volume") {
                        Picker("Poo Volume", selection: $pooVolume) {
                            ForEach(NappyVolumeChoice.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("nappy-poo-volume-picker")
                    }
                }

                if supportsPooColor {
                    Section("Poo Color") {
                        pooColorButtons
                    }
                }

                LoggingSummaryView(sentence: summarySentence)
            }
            .tint(Self.eventColor)
            .scrollContentBackground(.hidden)
            .background(Self.eventColor.opacity(0.08))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .onChange(of: type) { _, newType in
                if !NappyEntry.supportsPooColor(for: newType.value) {
                    pooColor = .notSet
                }
                if !NappyEntry.supportsPeeVolume(for: newType.value) {
                    peeVolume = .notSet
                }
                if !NappyEntry.supportsPooVolume(for: newType.value) {
                    pooVolume = .notSet
                }
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
                            supportsPeeVolume ? peeVolume.value : nil,
                            supportsPooVolume ? pooVolume.value : nil,
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

    private var typeSelectorButtons: some View {
        HStack(spacing: 8) {
            ForEach(NappyTypeChoice.allCases) { option in
                Button {
                    type = option
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(type == option ? Self.eventColor : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(type == option ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nappy-type-\(option.rawValue)")
            }
        }
    }

    private var pooColorButtons: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PooColorChoice.allCases) { option in
                Button {
                    pooColor = option
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(pooColor == option ? Self.eventColor : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(pooColor == option ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nappy-poo-color-\(option.rawValue)")
            }
        }
        .padding(.vertical, 2)
    }

    private var supportsPooColor: Bool {
        NappyEntry.supportsPooColor(for: type.value)
    }

    private var supportsPeeVolume: Bool {
        NappyEntry.supportsPeeVolume(for: type.value)
    }

    private var supportsPooVolume: Bool {
        NappyEntry.supportsPooVolume(for: type.value)
    }

    private var summarySentence: AttributedString {
        let timeStr = occurredAt.formatted(date: .omitted, time: .shortened)
        var s = summaryVariable(childName, color: Self.eventColor)
        s += AttributedString(" had a ")
        switch type {
        case .dry:
            s += summaryVariable("dry", color: Self.eventColor)
        case .wee:
            if peeVolume != .notSet {
                s += summaryVariable("\(peeVolume.title.lowercased()) wet", color: Self.eventColor)
            } else {
                s += summaryVariable("wet", color: Self.eventColor)
            }
        case .poo:
            var qualifiers: [String] = []
            if pooVolume != .notSet { qualifiers.append(pooVolume.title.lowercased()) }
            if pooColor != .notSet && pooColor != .other { qualifiers.append(pooColor.title.lowercased()) }
            qualifiers.append("dirty")
            s += summaryVariable(qualifiers.joined(separator: " "), color: Self.eventColor)
        case .mixed:
            s += summaryVariable("mixed", color: Self.eventColor)
        }
        s += AttributedString(" nappy at ")
        s += summaryVariable(timeStr, color: Self.eventColor)
        return s
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

        var id: String { rawValue }

        var title: String {
            switch self {
            case .dry: "Dry"
            case .wee: "Pee"
            case .poo: "Poo"
            case .mixed: "Mixed"
            }
        }

        var value: NappyType {
            NappyType(rawValue: rawValue) ?? .dry
        }
    }

    private enum NappyVolumeChoice: String, CaseIterable, Identifiable {
        case notSet
        case light
        case medium
        case heavy

        init(volume: NappyVolume?) {
            switch volume {
            case nil: self = .notSet
            case .light?: self = .light
            case .medium?: self = .medium
            case .heavy?: self = .heavy
            }
        }

        var id: String { rawValue }

        var title: String {
            switch self {
            case .notSet: "Not Set"
            case .light: "Light"
            case .medium: "Medium"
            case .heavy: "Heavy"
            }
        }

        var value: NappyVolume? {
            switch self {
            case .notSet: nil
            case .light: .light
            case .medium: .medium
            case .heavy: .heavy
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
            case nil: self = .notSet
            case .yellow?: self = .yellow
            case .mustard?: self = .mustard
            case .brown?: self = .brown
            case .green?: self = .green
            case .black?: self = .black
            case .other?: self = .other
            }
        }

        var id: String { rawValue }

        var title: String {
            switch self {
            case .notSet: "Not Set"
            case .yellow: "Yellow"
            case .mustard: "Mustard"
            case .brown: "Brown"
            case .green: "Green"
            case .black: "Black"
            case .other: "Other"
            }
        }

        var value: PooColor? {
            switch self {
            case .notSet: nil
            case .yellow: .yellow
            case .mustard: .mustard
            case .brown: .brown
            case .green: .green
            case .black: .black
            case .other: .other
            }
        }
    }
}

#Preview {
    NappyEditorSheetView(
        navigationTitle: "Log Nappy",
        primaryActionTitle: "Save",
        childName: "Robyn",
        initialType: .wee,
        initialOccurredAt: Date(),
        initialPeeVolume: .medium,
        initialPooVolume: nil,
        initialPooColor: nil
    ) { _, _, _, _, _ in true }
}
