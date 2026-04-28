import BabyTrackerDomain
import SwiftUI

/// The first-event logging step in the interactive onboarding flow.
///
/// Presents the real quick-log editor sheets so the user can log an event before
/// entering the main app. Buttons stagger in with a bouncy spring then cycle
/// through a zoom-up → wiggle → zoom-down sequence, matching the Quick Log
/// demo page. On a successful save the `onEventSaved` callback fires.
struct OnboardingFirstEventStepView: View {
    let model: AppModel
    let onEventSaved: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var activeEventSheet: ChildEventSheet?
    @State private var firstEventSaved = false
    @State private var appearedMask: [Bool] = Array(repeating: false, count: 6)
    @State private var highlightedIndex = 0
    @State private var wiggleScales: [Double] = Array(repeating: 1.0, count: 4)
    @State private var rotations: [Double] = Array(repeating: 0, count: 4)

    private var visibleKinds: [BabyEventKind] {
        BabyEventKind.allCases.filter { model.isEventKindEnabled($0) }
    }

    private var childName: String {
        model.currentChild?.name ?? "your baby"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Log your first event")
                        .font(.largeTitle.weight(.bold))
                        .opacity(appearedMask[0] ? 1 : 0)
                        .offset(y: appearedMask[0] ? 0 : 18)

                    Text("Try it now — pick whichever happened most recently.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(appearedMask[1] ? 1 : 0)
                        .offset(y: appearedMask[1] ? 0 : 14)
                }

                VStack(spacing: 12) {
                    let rows = stride(from: 0, to: visibleKinds.count, by: 2).map { i in
                        Array(visibleKinds[i..<min(i + 2, visibleKinds.count)])
                    }
                    ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 12) {
                            ForEach(Array(row.enumerated()), id: \.element) { colIndex, kind in
                                let buttonIndex = rowIndex * 2 + colIndex
                                quickLogButton(buttonIndex, title: buttonTitle(for: kind), kind: kind) {
                                    activeEventSheet = eventSheet(for: kind)
                                }
                            }
                        }
                        .geometryGroup()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            staggerIn()
        }
        .task(id: reduceMotion) {
            guard !reduceMotion else { return }
            let count = visibleKinds.count
            guard count > 0 else { return }
            // Wait for page slide-in + full stagger to settle before first wiggle
            try? await Task.sleep(for: .milliseconds(1200))
            animateWiggle(0)
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                guard !Task.isCancelled else { break }
                let next = (highlightedIndex + 1) % count
                withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                    highlightedIndex = next
                }
                animateWiggle(next)
            }
        }
        .sheet(item: $activeEventSheet, onDismiss: { activeEventSheet = nil }) { sheet in
            eventSheet(for: sheet)
        }
        .onChange(of: firstEventSaved) { _, saved in
            if saved { onEventSaved() }
        }
    }

    // MARK: - Kind helpers

    private func buttonTitle(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed: "Breast Feed"
        case .bottleFeed: "Bottle Feed"
        case .sleep: "Start Sleep"
        case .nappy: "Nappy"
        }
    }

    private func eventSheet(for kind: BabyEventKind) -> ChildEventSheet {
        switch kind {
        case .breastFeed: .quickLogBreastFeed
        case .bottleFeed: .quickLogBottleFeed(smartSuggestions: [])
        case .sleep: .startSleep(suggestions: [])
        case .nappy: .quickLogNappy(.mixed)
        }
    }

    // MARK: - Button

    private func quickLogButton(
        _ buttonIndex: Int,
        title: String,
        kind: BabyEventKind,
        action: @escaping () -> Void
    ) -> some View {
        let appeared = appearedMask[buttonIndex + 2]
        let isHighlighted = highlightedIndex == buttonIndex && appearedMask.allSatisfy { $0 }

        return Button(action: action) {
            Label(title, systemImage: BabyEventStyle.systemImage(for: kind))
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, 14)
                .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BabyEventStyle.buttonFillColor(for: kind))
                        .shadow(
                            color: BabyEventStyle.buttonFillColor(for: kind).opacity(isHighlighted ? 0.55 : 0),
                            radius: isHighlighted ? 10 : 0,
                            y: isHighlighted ? 4 : 0
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(wiggleScales[buttonIndex])
        .rotationEffect(.degrees(rotations[buttonIndex]))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 22)
    }

    // MARK: - Animation

    private func staggerIn() {
        if reduceMotion {
            appearedMask = Array(repeating: true, count: appearedMask.count)
            return
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(420))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                appearedMask[0] = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(0.08)) {
                appearedMask[1] = true
            }
            for index in 2..<(2 + visibleKinds.count) {
                let delay = Double(index - 2) * 0.1
                withAnimation(.spring(response: 0.38, dampingFraction: 0.52).delay(delay)) {
                    appearedMask[index] = true
                }
            }
        }
    }

    /// Plays a zoom-up → wiggle → zoom-down sequence on the button at `index`.
    private func animateWiggle(_ index: Int) {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.22, dampingFraction: 0.6)) {
            wiggleScales[index] = 1.03
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(160))
            let rotationSteps: [Double] = [2.2, -2.2, 1.4, 0]
            for rot in rotationSteps {
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.16, dampingFraction: 0.68)) {
                    rotations[index] = rot
                }
                try? await Task.sleep(for: .milliseconds(95))
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                wiggleScales[index] = 1.0
            }
        }
    }

    // MARK: - Event sheets

    @ViewBuilder
    private func eventSheet(for sheet: ChildEventSheet) -> some View {
        switch sheet {
        case .quickLogBreastFeed:
            BreastFeedEditorSheetView(
                navigationTitle: "Breast Feed",
                primaryActionTitle: "Save",
                childName: childName,
                initialDurationMinutes: 15,
                initialEndTime: Date(),
                initialSide: nil
            ) { durationMinutes, endTime, side, leftDurationSeconds, rightDurationSeconds in
                let didSave = model.logBreastFeed(
                    durationMinutes: durationMinutes,
                    endTime: endTime,
                    side: side,
                    leftDurationSeconds: leftDurationSeconds,
                    rightDurationSeconds: rightDurationSeconds
                )
                if didSave {
                    activeEventSheet = nil
                    firstEventSaved = true
                }
                return didSave
            }

        case let .quickLogBottleFeed(smartSuggestions):
            BottleFeedEditorSheetView(
                navigationTitle: "Bottle Feed",
                primaryActionTitle: "Save",
                childName: childName,
                preferredVolumeUnit: model.currentChild?.preferredFeedVolumeUnit ?? .milliliters,
                initialAmountMilliliters: 120,
                initialOccurredAt: Date(),
                initialMilkType: .formula,
                smartSuggestions: smartSuggestions
            ) { amountMilliliters, occurredAt, milkType in
                let didSave = model.logBottleFeed(
                    amountMilliliters: amountMilliliters,
                    occurredAt: occurredAt,
                    milkType: milkType
                )
                if didSave {
                    activeEventSheet = nil
                    firstEventSaved = true
                }
                return didSave
            }

        case let .startSleep(suggestions):
            SleepEditorSheetView(
                mode: .start,
                childName: childName,
                initialStartedAt: Date(),
                initialEndedAt: nil,
                startSuggestions: suggestions
            ) { startedAt, endedAt in
                let didSave: Bool
                if let endedAt {
                    didSave = model.logSleep(startedAt: startedAt, endedAt: endedAt)
                } else {
                    didSave = model.startSleep(startedAt: startedAt)
                }
                if didSave {
                    activeEventSheet = nil
                    firstEventSaved = true
                }
                return didSave
            }

        case let .quickLogNappy(type):
            NappyEditorSheetView(
                navigationTitle: "Nappy",
                primaryActionTitle: "Save",
                childName: childName,
                initialType: type,
                initialOccurredAt: Date(),
                initialPeeVolume: nil,
                initialPooVolume: nil,
                initialPooColor: nil
            ) { updatedType, occurredAt, peeVolume, pooVolume, pooColor in
                let didSave = model.logNappy(
                    type: updatedType,
                    occurredAt: occurredAt,
                    peeVolume: peeVolume,
                    pooVolume: pooVolume,
                    pooColor: pooColor
                )
                if didSave {
                    activeEventSheet = nil
                    firstEventSaved = true
                }
                return didSave
            }

        default:
            EmptyView()
        }
    }
}

#Preview {
    OnboardingFirstEventStepView(
        model: ChildProfilePreviewFactory.makeModel(),
        onEventSaved: {}
    )
}
