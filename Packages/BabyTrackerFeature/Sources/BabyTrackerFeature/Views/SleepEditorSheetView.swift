import BabyTrackerDomain
import SwiftUI

public struct SleepEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .sleep)

    let mode: Mode
    let childName: String
    let startSuggestions: [(label: String, date: Date)]
    let saveAction: (_ startedAt: Date, _ endedAt: Date?) -> Bool
    let deleteAction: (() -> Void)?
    let resumeAction: (() -> Void)?
    private let endTimeInitialPreset: QuickTimeSelectorView.TimePreset

    @Environment(\.dismiss) private var dismiss
    @State private var startedAt: Date
    @State private var showDeleteConfirmation = false
    @State private var endedAt: Date
    @State private var includesEndTime: Bool

    public init(
        mode: Mode,
        childName: String,
        initialStartedAt: Date,
        initialEndedAt: Date?,
        startSuggestions: [(label: String, date: Date)] = [],
        endTimeInitialPreset: QuickTimeSelectorView.TimePreset = .now,
        initialIncludesEndTime: Bool = false,
        saveAction: @escaping (_ startedAt: Date, _ endedAt: Date?) -> Bool,
        deleteAction: (() -> Void)? = nil,
        resumeAction: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.childName = childName
        self.startSuggestions = startSuggestions
        self.saveAction = saveAction
        self.deleteAction = deleteAction
        self.resumeAction = resumeAction
        self.endTimeInitialPreset = endTimeInitialPreset
        _startedAt = State(initialValue: initialStartedAt)
        _endedAt = State(initialValue: initialEndedAt ?? Date())
        _includesEndTime = State(initialValue: mode != .start || initialIncludesEndTime)
    }

    public var body: some View {
        NavigationStack {
            Form {
                LoggingSummaryView(sentence: summarySentence)

                switch mode {
                case .start:
                    startModeContent
                case .end:
                    endModeContent
                case .edit:
                    editModeContent
                }
                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if case .edit = mode, let resumeAction {
                    Section {
                        Button("Resume Sleep") {
                            resumeAction()
                        }
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("resume-sleep-button")
                    }
                }

                if deleteAction != nil {
                    Section {
                        Button("Delete Sleep", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("delete-sleep-button")
                    }
                }
            }
            .alert("Delete Sleep?", isPresented: $showDeleteConfirmation) {
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
                QuickTimeSelectorView(selection: $startedAt, buttonColor: Self.eventColor)
                    .accessibilityIdentifier("sleep-start-time-selector")
            }

            Section {
                Toggle("Already ended?", isOn: $includesEndTime)
                    .accessibilityIdentifier("sleep-includes-end-toggle")
            }

            if includesEndTime {
                Section {
                    durationSeparatorRow
                }
                Section("When did sleep end?") {
                    QuickTimeSelectorView(selection: $endedAt, initialPreset: endTimeInitialPreset, buttonColor: Self.eventColor)
                        .accessibilityIdentifier("sleep-end-time-selector")
                }
            }
        }
    }

    // MARK: - End Mode

    private var endModeContent: some View {
        Group {
            Section("When did sleep start?") {
                DatePicker(
                    "Started at",
                    selection: $startedAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityIdentifier("sleep-start-time-picker")
            }

            Section {
                durationSeparatorRow
            }

            Section("When did sleep end?") {
                QuickTimeSelectorView(selection: $endedAt, initialPreset: endTimeInitialPreset, buttonColor: Self.eventColor)
                    .accessibilityIdentifier("sleep-end-time-selector")
            }
        }
    }

    // MARK: - Edit Mode

    private var editModeContent: some View {
        Group {
            Section("When did sleep start?") {
                DatePicker(
                    "Start",
                    selection: $startedAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityIdentifier("sleep-start-time-picker")
            }

            Section {
                durationSeparatorRow
            }

            Section("When did sleep end?") {
                QuickTimeSelectorView(selection: $endedAt, initialPreset: endTimeInitialPreset, buttonColor: Self.eventColor)
                    .accessibilityIdentifier("sleep-end-time-selector")
            }
        }
    }

    // MARK: - Duration Separator

    private var durationSeparatorRow: some View {
        HStack(spacing: 6) {
            Spacer()
            Image(systemName: "moon.zzz.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(sleepDurationString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
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
                                    .fill(startedAt == suggestion.date ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
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

    private var summarySentence: AttributedString {
        var s = summaryVariable(childName, color: Self.eventColor)
        switch mode {
        case .start:
            let startTimeStr = startedAt.formatted(date: .omitted, time: .shortened)
            if includesEndTime {
                let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
                s += AttributedString(" slept from ")
                s += summaryVariable(startTimeStr, color: Self.eventColor)
                s += AttributedString(" to ")
                s += summaryVariable(endTimeStr, color: Self.eventColor)
                s += AttributedString(" (")
                s += summaryVariable(sleepDurationString, color: Self.eventColor)
                s += AttributedString(")")
            } else {
                s += AttributedString(" fell asleep at ")
                s += summaryVariable(startTimeStr, color: Self.eventColor)
            }
        case .end:
            let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
            s += AttributedString(" slept for ")
            s += summaryVariable(sleepDurationString, color: Self.eventColor)
            s += AttributedString(" until ")
            s += summaryVariable(endTimeStr, color: Self.eventColor)
        case .edit:
            let startTimeStr = startedAt.formatted(date: .omitted, time: .shortened)
            let endTimeStr = endedAt.formatted(date: .omitted, time: .shortened)
            s += AttributedString(" slept from ")
            s += summaryVariable(startTimeStr, color: Self.eventColor)
            s += AttributedString(" to ")
            s += summaryVariable(endTimeStr, color: Self.eventColor)
            s += AttributedString(" (")
            s += summaryVariable(sleepDurationString, color: Self.eventColor)
            s += AttributedString(")")
        }
        return s
    }

    private var sleepDurationString: String {
        let mins = max(0, Int(endedAt.timeIntervalSince(startedAt) / 60))
        return mins > 0 ? DurationText.short(minutes: mins, minuteStyle: .word) : "less than a minute"
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

#Preview("Edit with Resume") {
    SleepEditorSheetView(
        mode: .edit,
        childName: "Isla",
        initialStartedAt: Date(timeIntervalSinceNow: -7_200),
        initialEndedAt: Date(timeIntervalSinceNow: -1_800),
        endTimeInitialPreset: .custom,
        saveAction: { _, _ in true },
        resumeAction: {}
    )
}
