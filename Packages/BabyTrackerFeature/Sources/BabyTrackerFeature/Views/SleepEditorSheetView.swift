import SwiftUI

public struct SleepEditorSheetView: View {
    let mode: Mode
    let childName: String
    let startSuggestions: [(label: String, date: Date)]
    let saveAction: (_ startedAt: Date, _ endedAt: Date?) -> Bool
    let deleteAction: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var includesEndTime: Bool

    public init(
        mode: Mode,
        childName: String,
        initialStartedAt: Date,
        initialEndedAt: Date?,
        startSuggestions: [(label: String, date: Date)] = [],
        saveAction: @escaping (_ startedAt: Date, _ endedAt: Date?) -> Bool,
        deleteAction: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.childName = childName
        self.startSuggestions = startSuggestions
        self.saveAction = saveAction
        self.deleteAction = deleteAction
        _startedAt = State(initialValue: initialStartedAt)
        _endedAt = State(initialValue: initialEndedAt ?? Date())
        _includesEndTime = State(initialValue: mode != .start)
    }

    public var body: some View {
        NavigationStack {
            Form {
                switch mode {
                case .start:
                    startModeContent
                case .end:
                    endModeContent
                case .edit:
                    editModeContent
                }

                LoggingSummaryView(sentence: summarySentence)

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if let deleteAction {
                    Section {
                        Button("Delete Sleep", role: .destructive) {
                            deleteAction()
                            dismiss()
                        }
                        .accessibilityIdentifier("delete-sleep-button")
                    }
                }
            }
            .navigationTitle(mode.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .onChange(of: startedAt) { _, updatedStart in
                if endedAt < updatedStart {
                    endedAt = updatedStart
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        let didSave = saveAction(startedAt, shouldIncludeEndTime ? endedAt : nil)
                        if didSave { dismiss() }
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save-sleep-button")
                }
            }
        }
    }

    // MARK: - Start Mode

    private var startModeContent: some View {
        Group {
            Section("When did sleep start?") {
                if !startSuggestions.isEmpty {
                    suggestionButtons
                }
                QuickTimeSelectorView(selection: $startedAt)
                    .accessibilityIdentifier("sleep-start-time-selector")
            }

            Section {
                Toggle("Already ended?", isOn: $includesEndTime)
                    .accessibilityIdentifier("sleep-includes-end-toggle")
            }

            if includesEndTime {
                Section("When did sleep end?") {
                    QuickTimeSelectorView(selection: $endedAt)
                        .accessibilityIdentifier("sleep-end-time-selector")
                }
            }
        }
    }

    // MARK: - End Mode

    private var endModeContent: some View {
        Group {
            Section("Sleep started") {
                DatePicker(
                    "Started at",
                    selection: $startedAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityIdentifier("sleep-start-time-picker")
            }

            Section("When did sleep end?") {
                QuickTimeSelectorView(selection: $endedAt)
                    .accessibilityIdentifier("sleep-end-time-selector")
            }
        }
    }

    // MARK: - Edit Mode

    private var editModeContent: some View {
        Group {
            Section("Start time") {
                DatePicker(
                    "Start",
                    selection: $startedAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityIdentifier("sleep-start-time-picker")
            }
            Section("End time") {
                QuickTimeSelectorView(selection: $endedAt)
                    .accessibilityIdentifier("sleep-end-time-selector")
            }
        }
    }

    // MARK: - Suggestions

    private var suggestionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(startSuggestions, id: \.label) { suggestion in
                    Button {
                        startedAt = suggestion.date
                    } label: {
                        Text(suggestion.label)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(startedAt == suggestion.date ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                            )
                            .foregroundStyle(startedAt == suggestion.date ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("sleep-start-suggestion-\(suggestion.label)")
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Summary

    private var summarySentence: String {
        switch mode {
        case .start:
            let startTimeStr = startedAt.formatted(date: .omitted, time: .shortened)
            if includesEndTime {
                let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
                return "\(childName) slept from \(startTimeStr) to \(endTimeStr) (\(sleepDurationString))"
            }
            return "\(childName) fell asleep at \(startTimeStr)"
        case .end:
            let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
            return "\(childName) slept for \(sleepDurationString) until \(endTimeStr)"
        case .edit:
            let startTimeStr = startedAt.formatted(date: .omitted, time: .shortened)
            let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
            return "\(childName) slept from \(startTimeStr) to \(endTimeStr) (\(sleepDurationString))"
        }
    }

    private var sleepDurationString: String {
        let mins = max(0, Int(endedAt.timeIntervalSince(startedAt) / 60))
        let hours = mins / 60
        let remaining = mins % 60
        if hours > 0 {
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        } else if mins > 0 {
            return "\(mins) min"
        } else {
            return "less than a minute"
        }
    }

    // MARK: - Validation

    private var shouldIncludeEndTime: Bool {
        switch mode {
        case .start: return includesEndTime
        case .end, .edit: return true
        }
    }

    private var saveButtonTitle: String {
        switch mode {
        case .start: return includesEndTime ? "Log Sleep" : "Start Sleep"
        case .end: return "End Sleep"
        case .edit: return "Update"
        }
    }

    private var isValid: Bool {
        guard shouldIncludeEndTime else { return true }
        return endedAt > startedAt
    }

    private var validationMessage: String? {
        guard shouldIncludeEndTime, !isValid else { return nil }
        return "End time must be later than the start time."
    }
}

extension SleepEditorSheetView {
    public enum Mode {
        case start
        case end
        case edit

        public var navigationTitle: String {
            switch self {
            case .start: "Log Sleep"
            case .end: "End Sleep"
            case .edit: "Edit Sleep"
            }
        }

        public var showsEndTime: Bool {
            switch self {
            case .start: false
            case .end, .edit: true
            }
        }
    }
}
