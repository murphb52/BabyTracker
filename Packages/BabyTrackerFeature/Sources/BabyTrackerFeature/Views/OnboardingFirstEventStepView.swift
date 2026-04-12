import BabyTrackerDomain
import SwiftUI

/// The first-event logging step in the interactive onboarding flow.
/// Presents the real quick-log editor sheets so the user can log an event before
/// entering the main app. On a successful save the `onEventSaved` callback fires.
struct OnboardingFirstEventStepView: View {
    let model: AppModel
    let onEventSaved: () -> Void
    let skipAction: () -> Void

    @State private var activeEventSheet: ChildEventSheet?
    @State private var firstEventSaved = false

    private var childName: String {
        model.currentChild?.name ?? "your baby"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Log your first event")
                        .font(.largeTitle.weight(.bold))

                    Text("Try it now — pick whichever happened most recently.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        quickLogButton("Breast Feed", kind: .breastFeed) {
                            activeEventSheet = .quickLogBreastFeed
                        }
                        quickLogButton("Bottle Feed", kind: .bottleFeed) {
                            activeEventSheet = .quickLogBottleFeed
                        }
                    }

                    HStack(spacing: 12) {
                        quickLogButton("Start Sleep", kind: .sleep) {
                            activeEventSheet = .startSleep(suggestions: [])
                        }
                        quickLogButton("Nappy", kind: .nappy) {
                            activeEventSheet = .quickLogNappy(.mixed)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 8)
        }
        .scrollBounceBehavior(.basedOnSize)
        .sheet(item: $activeEventSheet, onDismiss: { activeEventSheet = nil }) { sheet in
            eventSheet(for: sheet)
        }
        .onChange(of: firstEventSaved) { _, saved in
            if saved { onEventSaved() }
        }
    }

    private func quickLogButton(
        _ title: String,
        kind: BabyEventKind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: BabyEventStyle.systemImage(for: kind))
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, 14)
                .foregroundStyle(BabyEventStyle.buttonForegroundColor(for: kind))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(BabyEventStyle.buttonFillColor(for: kind))
                )
        }
        .buttonStyle(.plain)
    }

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

        case .quickLogBottleFeed:
            BottleFeedEditorSheetView(
                navigationTitle: "Bottle Feed",
                primaryActionTitle: "Save",
                childName: childName,
                preferredVolumeUnit: model.currentChild?.preferredFeedVolumeUnit ?? .milliliters,
                initialAmountMilliliters: 120,
                initialOccurredAt: Date(),
                initialMilkType: .formula
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
        onEventSaved: {},
        skipAction: {}
    )
}
