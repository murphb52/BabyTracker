import BabyTrackerDomain
import SwiftUI

public struct BreastFeedEditorSheetView: View {
    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
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
    // leftFraction: 0.0 = all right, 0.5 = 50/50, 1.0 = all left
    @State private var leftFraction: Double = 0.5

    private let quickDurations = [5, 10, 15, 20, 30]

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        initialDurationMinutes: Int,
        initialEndTime: Date,
        initialSide: BreastSide?,
        initialLeftDurationSeconds: Int? = nil,
        initialRightDurationSeconds: Int? = nil,
        saveAction: @escaping (_ durationMinutes: Int, _ endTime: Date, _ side: BreastSide?, _ leftDurationSeconds: Int?, _ rightDurationSeconds: Int?) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.saveAction = saveAction
        _durationMinutes = State(initialValue: initialDurationMinutes > 0 ? "\(initialDurationMinutes)" : "")
        _endTime = State(initialValue: initialEndTime)
        _side = State(initialValue: BreastSideChoice(side: initialSide))

        if let left = initialLeftDurationSeconds,
           let right = initialRightDurationSeconds,
           left + right > 0 {
            _leftFraction = State(initialValue: Double(left) / Double(left + right))
            _showPerSideBreakdown = State(initialValue: true)
        } else if initialLeftDurationSeconds != nil || initialRightDurationSeconds != nil {
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

                LoggingSummaryView(sentence: summarySentence)
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
                    sideTimerButton(label: "Left", elapsed: leftElapsed, isRunning: leftRunning, identifier: "left") {
                        toggleLeft()
                    }
                    sideTimerButton(label: "Right", elapsed: rightElapsed, isRunning: rightRunning, identifier: "right") {
                        toggleRight()
                    }
                }
                .padding(.vertical, 8)
            }

            if timerStarted {
                Section {
                    HStack {
                        Text("Total").foregroundStyle(.secondary)
                        Spacer()
                        Text(formatDuration(leftElapsed + rightElapsed)).monospacedDigit()
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
                Text(label).font(.headline)
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
        if !timerStarted { sessionStartedAt = Date(); timerStarted = true }
        if leftRunning {
            leftRunning = false
        } else {
            rightRunning = false
            leftRunning = true
        }
    }

    private func toggleRight() {
        if !timerStarted { sessionStartedAt = Date(); timerStarted = true }
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
            Section("Duration") {
                quickDurationButtons

                TextField("Total duration (minutes)", text: $durationMinutes)
                    .keyboardType(.numberPad)
                    .accessibilityIdentifier("breast-feed-duration-field")

                Picker("Side", selection: $side) {
                    ForEach(BreastSideChoice.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("breast-feed-side-picker")

                if side == .both {
                    if let total = parsedDurationMinutes {
                        perSideBreakdown(total: total)
                    }
                }
            }

            Section("When was the feed?") {
                QuickTimeSelectorView(selection: $endTime)
                    .accessibilityIdentifier("breast-feed-time-selector")
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
                    Text("\(duration)m")
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

    @ViewBuilder
    private func perSideBreakdown(total: Int) -> some View {
        Toggle("Show per-side breakdown", isOn: $showPerSideBreakdown)
            .accessibilityIdentifier("breast-feed-per-side-toggle")

        if showPerSideBreakdown {
            let leftMins = leftMinutes(total: total)
            let rightMins = total - leftMins

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Left").font(.caption).foregroundStyle(.secondary)
                    Text("\(leftMins) min").font(.subheadline.weight(.semibold)).monospacedDigit()
                }
                Spacer()
                if leftMins == rightMins {
                    Text("50/50").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Right").font(.caption).foregroundStyle(.secondary)
                    Text("\(rightMins) min").font(.subheadline.weight(.semibold)).monospacedDigit()
                }
            }

            Slider(value: $leftFraction, in: 0...1, step: 1.0 / Double(max(total, 1)))
                .accessibilityIdentifier("breast-feed-split-slider")
        }
    }

    private func leftMinutes(total: Int) -> Int {
        min(total, max(0, Int(round(leftFraction * Double(total)))))
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
        mode == .timer ? (timerStarted && (leftElapsed + rightElapsed) > 0) : parsedDurationMinutes != nil
    }

    private func handleSave() {
        if mode == .timer {
            leftRunning = false
            rightRunning = false
            let totalSeconds = Int(leftElapsed + rightElapsed)
            let durationMins = max(1, totalSeconds / 60)
            let derivedSide: BreastSide?
            if leftElapsed > 0 && rightElapsed > 0 { derivedSide = .both }
            else if leftElapsed > 0 { derivedSide = .left }
            else if rightElapsed > 0 { derivedSide = .right }
            else { derivedSide = nil }
            let didSave = saveAction(
                durationMins, Date(), derivedSide,
                leftElapsed > 0 ? Int(leftElapsed) : nil,
                rightElapsed > 0 ? Int(rightElapsed) : nil
            )
            if didSave { dismiss() }
        } else {
            guard let total = parsedDurationMinutes else { return }
            var leftSecs: Int?
            var rightSecs: Int?
            if showPerSideBreakdown && side == .both {
                let leftMins = leftMinutes(total: total)
                leftSecs = leftMins * 60
                rightSecs = (total - leftMins) * 60
            }
            let didSave = saveAction(total, endTime, side.value, leftSecs, rightSecs)
            if didSave { dismiss() }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private var summarySentence: String {
        if mode == .timer {
            guard timerStarted else {
                return "\(childName) is about to breast feed"
            }
            let total = leftElapsed + rightElapsed
            let mins = Int(total / 60)
            let durationStr = mins == 0 ? "less than a minute" : "\(mins) min"
            let hasLeft = leftElapsed > 0
            let hasRight = rightElapsed > 0
            if hasLeft && hasRight {
                return "\(childName) has fed on both sides for \(durationStr)"
            } else if hasLeft {
                return "\(childName) has fed on the left for \(durationStr)"
            } else {
                return "\(childName) has fed on the right for \(durationStr)"
            }
        } else {
            let timeStr = endTime.formatted(date: .omitted, time: .shortened)
            guard let total = parsedDurationMinutes else {
                return "\(childName) breast fed at \(timeStr)"
            }
            let durationStr = total == 1 ? "1 minute" : "\(total) minutes"
            switch side {
            case .notSet:
                return "\(childName) breast fed for \(durationStr) at \(timeStr)"
            case .left:
                return "\(childName) fed on the left for \(durationStr) at \(timeStr)"
            case .right:
                return "\(childName) fed on the right for \(durationStr) at \(timeStr)"
            case .both:
                return "\(childName) fed on both sides for \(durationStr) at \(timeStr)"
            }
        }
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

    enum BreastSideChoice: String, CaseIterable, Identifiable {
        case left
        case right
        case both
        case notSet

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
            case .left: "Left"
            case .right: "Right"
            case .both: "Both"
            case .notSet: "—"
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
        childName: "Robyn",
        initialDurationMinutes: 15,
        initialEndTime: Date(),
        initialSide: .both
    ) { _, _, _, _, _ in true }
}
