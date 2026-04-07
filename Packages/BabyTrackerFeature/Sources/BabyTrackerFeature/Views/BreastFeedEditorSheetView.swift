import BabyTrackerDomain
import SwiftUI

public struct BreastFeedEditorSheetView: View {
    private static let eventColor = BabyEventStyle.accentColor(for: .breastFeed)

    public enum Mode {
        case start
        case end
        case manual
    }

    let navigationTitle: String
    let primaryActionTitle: String
    let childName: String
    let mode: Mode
    let startAction: (_ startedAt: Date, _ side: BreastSide?) -> Bool
    let endAction: (_ endTime: Date, _ side: BreastSide?, _ leftDurationSeconds: Int?, _ rightDurationSeconds: Int?, _ durationMinutes: Int) -> Bool
    let resumeAction: (() -> Void)?
    private let initialTimePreset: QuickTimeSelectorView.TimePreset

    @Environment(\.dismiss) private var dismiss

    @State private var startedAt: Date
    @State private var endTime: Date
    @State private var side: BreastSideChoice
    @State private var leftElapsed: TimeInterval = 0
    @State private var rightElapsed: TimeInterval = 0
    @State private var durationMinutes: String
    @State private var showPerSideBreakdown: Bool = false
    @State private var leftFraction: Double = 0.5
    @State private var showCustomDuration: Bool = false

    private let quickDurations = [5, 10, 15, 20, 30]

    public init(
        navigationTitle: String,
        primaryActionTitle: String,
        childName: String,
        initialDurationMinutes: Int,
        initialEndTime: Date,
        initialSide: BreastSide?,
        mode: Mode,
        initialStartedAt: Date = Date(),
        initialTimePreset: QuickTimeSelectorView.TimePreset = .now,
        initialLeftDurationSeconds: Int? = nil,
        initialRightDurationSeconds: Int? = nil,
        startAction: @escaping (_ startedAt: Date, _ side: BreastSide?) -> Bool = { _, _ in false },
        resumeAction: (() -> Void)? = nil,
        endAction: @escaping (_ endTime: Date, _ side: BreastSide?, _ leftDurationSeconds: Int?, _ rightDurationSeconds: Int?, _ durationMinutes: Int) -> Bool
    ) {
        self.navigationTitle = navigationTitle
        self.primaryActionTitle = primaryActionTitle
        self.childName = childName
        self.mode = mode
        self.startAction = startAction
        self.resumeAction = resumeAction
        self.endAction = endAction
        self.initialTimePreset = initialTimePreset

        _startedAt = State(initialValue: initialStartedAt)
        _endTime = State(initialValue: initialEndTime)
        _durationMinutes = State(initialValue: initialDurationMinutes > 0 ? "\(initialDurationMinutes)" : "")
        _side = State(initialValue: BreastSideChoice(side: initialSide))
        _leftElapsed = State(initialValue: TimeInterval(initialLeftDurationSeconds ?? 0))
        _rightElapsed = State(initialValue: TimeInterval(initialRightDurationSeconds ?? 0))

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
                LoggingSummaryView(sentence: summarySentence)

                switch mode {
                case .start:
                    startModeContent
                case .end:
                    endModeContent
                case .manual:
                    manualModeContent
                }

                if mode == .manual, let resumeAction {
                    Section {
                        Button("Resume Breast Feed") {
                            resumeAction()
                            dismiss()
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            .tint(Self.eventColor)
            .scrollContentBackground(.hidden)
            .background(Self.eventColor.opacity(0.08))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.large])
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

    private var startModeContent: some View {
        Group {
            Section("When did breast feeding start?") {
                QuickTimeSelectorView(selection: $startedAt)
            }

            Section("Side") {
                Picker("Side", selection: $side) {
                    ForEach(BreastSideChoice.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var endModeContent: some View {
        Group {
            Section("When did breast feeding start?") {
                DatePicker(
                    "Started at",
                    selection: $startedAt,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Section("When did breast feeding end?") {
                QuickTimeSelectorView(selection: $endTime, initialPreset: initialTimePreset)
            }

            Section("Side") {
                Picker("Side", selection: $side) {
                    ForEach(BreastSideChoice.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let duration = endDurationMinutes {
                Section {
                    Text("Duration: \(DurationText.short(minutes: duration, minuteStyle: .word))")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var manualModeContent: some View {
        Group {
            Section("When was the feed?") {
                QuickTimeSelectorView(selection: $endTime, initialPreset: initialTimePreset)
                    .accessibilityIdentifier("breast-feed-time-selector")
            }

            Section("Duration") {
                quickDurationButtons

                if showCustomDuration {
                    TextField("Enter duration in minutes", text: $durationMinutes)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("breast-feed-duration-field")
                }

                Picker("Side", selection: $side) {
                    ForEach(BreastSideChoice.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("breast-feed-side-picker")

                if side == .both, let total = parsedDurationMinutes {
                    perSideBreakdown(total: total)
                }
            }
        }
    }

    private var quickDurationButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickDurations, id: \.self) { duration in
                    Button {
                        showCustomDuration = false
                        durationMinutes = "\(duration)"
                    } label: {
                        Text("\(duration)m")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(!showCustomDuration && parsedDurationMinutes == duration ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                            )
                            .foregroundStyle(!showCustomDuration && parsedDurationMinutes == duration ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    showCustomDuration = true
                    durationMinutes = ""
                } label: {
                    Text("Custom")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(showCustomDuration ? Self.eventColor : Color(.tertiarySystemGroupedBackground))
                        )
                        .foregroundStyle(showCustomDuration ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func perSideBreakdown(total: Int) -> some View {
        Toggle("Show per-side breakdown", isOn: $showPerSideBreakdown)

        if showPerSideBreakdown {
            let leftMins = leftMinutes(total: total)
            let rightMins = total - leftMins

            HStack {
                Text("Left: \(DurationText.short(minutes: leftMins, minuteStyle: .word))")
                Spacer()
                Text("Right: \(DurationText.short(minutes: rightMins, minuteStyle: .word))")
            }

            Slider(value: $leftFraction, in: 0...1, step: 1.0 / Double(max(total, 1)))
        }
    }

    private func leftMinutes(total: Int) -> Int {
        min(total, max(0, Int(round(leftFraction * Double(total)))))
    }

    private var parsedDurationMinutes: Int? {
        guard let v = Int(durationMinutes.trimmingCharacters(in: .whitespacesAndNewlines)), v > 0 else { return nil }
        return v
    }

    private var endDurationMinutes: Int? {
        guard endTime > startedAt else { return nil }
        return max(1, Int(endTime.timeIntervalSince(startedAt) / 60))
    }

    private var canSave: Bool {
        switch mode {
        case .start:
            return true
        case .end:
            return endTime > startedAt
        case .manual:
            return parsedDurationMinutes != nil
        }
    }

    private func handleSave() {
        switch mode {
        case .start:
            let didSave = startAction(startedAt, side.value)
            if didSave { dismiss() }
        case .end:
            let duration = endDurationMinutes ?? 1
            let didSave = endAction(endTime, side.value, leftDurationSeconds(from: duration), rightDurationSeconds(from: duration), duration)
            if didSave { dismiss() }
        case .manual:
            guard let total = parsedDurationMinutes else { return }
            let didSave = endAction(endTime, side.value, leftDurationSeconds(from: total), rightDurationSeconds(from: total), total)
            if didSave { dismiss() }
        }
    }

    private func leftDurationSeconds(from totalMinutes: Int) -> Int? {
        if side != .both { return nil }
        if showPerSideBreakdown {
            return leftMinutes(total: totalMinutes) * 60
        }
        return nil
    }

    private func rightDurationSeconds(from totalMinutes: Int) -> Int? {
        if side != .both { return nil }
        if showPerSideBreakdown {
            return (totalMinutes - leftMinutes(total: totalMinutes)) * 60
        }
        return nil
    }

    private var summarySentence: AttributedString {
        var s = summaryVariable(childName, color: Self.eventColor)
        switch mode {
        case .start:
            s += AttributedString(" is about to breast feed")
        case .end:
            s += AttributedString(" has breast fed since ")
            s += summaryVariable(startedAt.formatted(date: .omitted, time: .shortened), color: Self.eventColor)
        case .manual:
            s += AttributedString(" breast fed at ")
            s += summaryVariable(endTime.formatted(date: .omitted, time: .shortened), color: Self.eventColor)
        }
        return s
    }
}

extension BreastFeedEditorSheetView {
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
        navigationTitle: "Breast Feed",
        primaryActionTitle: "Save",
        childName: "Robyn",
        initialDurationMinutes: 15,
        initialEndTime: Date(),
        initialSide: .both,
        mode: .manual,
        endAction: { _, _, _, _, _ in true }
    )
}
