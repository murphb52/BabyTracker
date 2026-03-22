import BabyTrackerDomain
import SwiftUI

struct BreastFeedEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let saveAction: (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var durationMinutes: String
    @State private var endTime: Date
    @State private var side: BreastSideChoice

    private let quickDurations = [5, 10, 15]

    init(
        navigationTitle: String,
        primaryActionTitle: String,
        initialDurationMinutes: Int,
        initialEndTime: Date,
        initialSide: BreastSide?,
        saveAction: @escaping (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.saveAction = saveAction
        _durationMinutes = State(initialValue: "\(initialDurationMinutes)")
        _endTime = State(initialValue: initialEndTime)
        _side = State(initialValue: BreastSideChoice(side: initialSide))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick Duration") {
                    quickDurationButtons
                }

                Section("Feed") {
                    TextField("Duration (minutes)", text: $durationMinutes)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("breast-feed-duration-field")

                    DatePicker(
                        "End time",
                        selection: $endTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("breast-feed-end-time-picker")

                    Picker("Side", selection: $side) {
                        ForEach(BreastSideChoice.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("breast-feed-side-picker")
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
                        guard let durationValue = parsedDurationMinutes else {
                            return
                        }

                        let didSave = saveAction(durationValue, endTime, side.value)
                        if didSave {
                            dismiss()
                        }
                    }
                    .disabled(parsedDurationMinutes == nil)
                    .accessibilityIdentifier("save-breast-feed-button")
                }
            }
        }
    }

    private var quickDurationButtons: some View {
        HStack(spacing: 8) {
            ForEach(quickDurations, id: \.self) { duration in
                Button {
                    durationMinutes = "\(duration)"
                } label: {
                    Text("\(duration) min")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected(duration: duration) ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(isSelected(duration: duration) ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("breast-feed-duration-preset-\(duration)")
            }
        }
    }

    private var parsedDurationMinutes: Int? {
        guard let durationValue = Int(durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)),
              durationValue > 0 else {
            return nil
        }

        return durationValue
    }

    private var validationMessage: String? {
        guard !durationMinutes.isEmpty, parsedDurationMinutes == nil else {
            return nil
        }

        return "Enter a duration greater than 0 minutes."
    }

    private func isSelected(duration: Int) -> Bool {
        parsedDurationMinutes == duration
    }
}

extension BreastFeedEditorSheetView {
    private enum BreastSideChoice: String, CaseIterable, Identifiable {
        case notSet
        case left
        case right
        case both

        init(side: BreastSide?) {
            switch side {
            case nil:
                self = .notSet
            case .left?:
                self = .left
            case .right?:
                self = .right
            case .both?:
                self = .both
            }
        }

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .notSet:
                "Not Set"
            case .left:
                "Left"
            case .right:
                "Right"
            case .both:
                "Both"
            }
        }

        var value: BreastSide? {
            switch self {
            case .notSet:
                nil
            case .left:
                .left
            case .right:
                .right
            case .both:
                .both
            }
        }
    }
}
