import BabyTrackerDomain
import SwiftUI

public struct BreastFeedEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let saveAction: (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?, _ leftDurationSeconds: Int?, _ rightDurationSeconds: Int?) -> Bool

    @Environment(\.dismiss) private var dismiss

    // Mode
    @State private var mode: FeedMode = .timer

    // Timer mode state
    @State private var sessionStartedAt: Date = Date()
    @State private var leftElapsed: TimeInterval = 0
    @State private var rightElapsed: TimeInterval = 0
    @State private var leftRunning: Bool = false
    @State private var rightRunning: Bool = false
    @State private var timerStarted: Bool = false

    // Manual mode state
    @State private var durationMinutes: String
    @State private var endTime: Date
    @State private var side: BreastSideChoice
    @State private var showPerSideBreakdown: Bool = false
    @State private var leftDurationMinutes: String = ""
    @State private var rightDurationMinutes: String = ""

    private let quickDurations = [5, 10, 15]

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        initialDurationMinutes: Int,
        initialEndTime: Date,
        initialSide: BreastSide?,
        initialLeftDurationSeconds: Int? = nil,
        initialRightDurationSeconds: Int? = nil,
        saveAction: @escaping (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?, _ leftDurationSeconds: Int?, _ rightDurationSeconds: Int?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.saveAction = saveAction
        _durationMinutes = State(initialValue: "\(initialDurationMinutes)")
        _endTime = State(initialValue: initialEndTime)
        _side = State(initialValue: BreastSideChoice(side: initialSide))
        if let left = initialLeftDurationSeconds {
            _leftDurationMinutes = State(initialValue: "\(left / 60)")
        }
        if let right = initialRightDurationSeconds {
            _rightDurationMinutes = State(initialValue: "\(right / 60)")
        }
        if initialLeftDurationSeconds != nil || initialRightDurationSeconds != nil {
            _showPerSideBreakdown = State(initialValue: true)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $mode) {
                        ForEach(FeedMode.allCases) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("breast-feed-mode-picker")
                }

                if mode == .timer {
                    timerModeContent
                } else {
                    manualModeContent
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
            .onReceive(
                Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            ) { _ in
                if leftRunning { leftElapsed += 1 }
                if rightRunning { rightElapsed += 1 }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) {
                        handleSave()
                    }
                    .disabled(!canSave)
                    .accessibilityIdentifier("save-breast-feed-button")
                }
            }
        }
    }

    // MARK: - Timer Mode

    private var timerModeContent: some View {
        Group {
            Section {
                HStack(spacing: 16) {
                    sideTimerButton(
                        label: "Left",
                        elapsed: leftElapsed,
                        isRunning: leftRunning,
                        identifier: "left"
                    ) {
                        toggleLeft()
                    }
                    sideTimerButton(
                        label: "Right",
                        elapsed: rightElapsed,
                        isRunning: rightRunning,
                        identifier: "right"
                    ) {
                        toggleRight()
                    }
                }
                .padding(.vertical, 8)
            }

            if timerStarted {
                Section {
                    HStack {
                        Text("Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(leftElapsed + rightElapsed))
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private func sideTimerButton(
        label: String,
        elapsed: TimeInterval,
        isRunning: Bool,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(label)
                    .font(.headline)
                Text(formatDuration(elapsed))
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(isRunning ? Color.accentColor : Color.primary)
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(isRunning ? Color.accentColor : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isRunning ? Color.accentColor.opacity(0.12) : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("breast-feed-timer-\(identifier)")
    }

    private func toggleLeft() {
        if !timerStarted {
            sessionStartedAt = Date()
            timerStarted = true
        }
        if leftRunning {
            leftRunning = false
        } else {
            rightRunning = false
            leftRunning = true
        }
    }

    private func toggleRight() {
        if !timerStarted {
            sessionStartedAt = Date()
            timerStarted = true
        }
        if rightRunning {
            rightRunning = false
        } else {
            leftRunning = false
            rightRunning = true
        }
    }

    // MARK: - Manual Mode

    private var manualModeContent: some View {
        Group {
            Section("Time") {
                QuickTimeSelectorView(selection: $endTime)
                    .accessibilityIdentifier("breast-feed-time-selector")
            }

            Section("Quick Duration") {
                quickDurationButtons
            }

            Section("Duration") {
                TextField("Total duration (minutes)", text: $durationMinutes)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("breast-feed-duration-field")

                Picker("Side", selection: $side) {
                    ForEach(BreastSideChoice.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .accessibilityIdentifier("breast-feed-side-picker")
            }

            Section {
                Toggle("Add per-side breakdown", isOn: $showPerSideBreakdown)
                    .accessibilityIdentifier("breast-feed-per-side-toggle")
                if showPerSideBreakdown {
                    TextField("Left boob (minutes)", text: $leftDurationMinutes)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("breast-feed-left-duration-field")
                    TextField("Right boob (minutes)", text: $rightDurationMinutes)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("breast-feed-right-duration-field")
                }
            }

            if let msg = manualValidationMessage {
                Section {
                    Text(msg).foregroundStyle(.red)
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
                                .fill(parsedDurationMinutes == duration ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                        )
                        .foregroundStyle(parsedDurationMinutes == duration ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("breast-feed-duration-preset-\(duration)")
            }
        }
    }

    // MARK: - Helpers

    private var parsedDurationMinutes: Int? {
        guard let v = Int(durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)), v > 0 else { return nil }
        return v
    }

    private var manualValidationMessage: String? {
        guard !durationMinutes.isEmpty, parsedDurationMinutes == nil else { return nil }
        return "Enter a duration greater than 0 minutes."
    }

    private var canSave: Bool {
        if mode == .timer {
            return timerStarted && (leftElapsed + rightElapsed) > 0
        } else {
            return parsedDurationMinutes != nil
        }
    }

    private func handleSave() {
        if mode == .timer {
            leftRunning = false
            rightRunning = false
            let totalSeconds = Int(leftElapsed + rightElapsed)
            let durationMins = max(1, totalSeconds / 60)
            let endTimeNow = Date()
            let derivedSide: BreastSide?
            if leftElapsed > 0 && rightElapsed > 0 { derivedSide = .both }
            else if leftElapsed > 0 { derivedSide = .left }
            else if rightElapsed > 0 { derivedSide = .right }
            else { derivedSide = nil }
            let didSave = saveAction(
                durationMins,
                endTimeNow,
                derivedSide,
                leftElapsed > 0 ? Int(leftElapsed) : nil,
                rightElapsed > 0 ? Int(rightElapsed) : nil
            )
            if didSave { dismiss() }
        } else {
            guard let durationValue = parsedDurationMinutes else { return }
            let leftSecs: Int? = showPerSideBreakdown ? Int(leftDurationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 * 60 } : nil
            let rightSecs: Int? = showPerSideBreakdown ? Int(rightDurationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)).map { $0 * 60 } : nil
            let didSave = saveAction(durationValue, endTime, side.value, leftSecs, rightSecs)
            if didSave { dismiss() }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

extension BreastFeedEditorSheetView {
    enum FeedMode: String, CaseIterable, Identifiable {
        case timer, manual
        var id: String { rawValue }
        var label: String {
            switch self {
            case .timer: "Timer"
            case .manual: "Manual"
            }
        }
    }

    private enum BreastSideChoice: String, CaseIterable, Identifiable {
        case notSet
        case left
        case right
        case both

        init(side: BreastSide?) {
            switch side {
            case nil: self = .notSet
            case .left?: self = .left
            case .right?: self = .right
            case .both?: self = .both
            }
        }

        var id: String { rawValue }

        var title: String {
            switch self {
            case .notSet: "Not Set"
            case .left: "Left"
            case .right: "Right"
            case .both: "Both"
            }
        }

        var value: BreastSide? {
            switch self {
            case .notSet: nil
            case .left: .left
            case .right: .right
            case .both: .both
            }
        }
    }
}

#Preview {
    BreastFeedEditorSheetView(
        navigationTitle: "Log Feed",
        primaryActionTitle: "Save",
        initialDurationMinutes: 15,
        initialEndTime: Date(),
        initialSide: .both
    ) { _, _, _, _, _ in true }
}
