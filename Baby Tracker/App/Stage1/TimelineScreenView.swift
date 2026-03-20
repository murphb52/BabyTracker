import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct TimelineScreenView: View {
    let model: AppModel

    @State private var activeEvent: TimelineEventRowViewState?
    @State private var deleteCandidate: TimelineEventRowViewState?

    var body: some View {
        if let profile = model.profile {
            timelineContent(
                timeline: profile.timeline,
                canManageEvents: profile.canManageEvents
            )
            .navigationTitle("Timeline")
            .sheet(item: $activeEvent) { event in
                eventSheet(for: event, canManageEvents: profile.canManageEvents)
            }
            .confirmationDialog(
                deleteDialogTitle,
                isPresented: deleteConfirmationIsPresented,
                titleVisibility: .visible,
                presenting: deleteCandidate
            ) { event in
                Button(deleteConfirmTitle(for: event), role: .destructive) {
                    _ = model.deleteEvent(id: event.id)
                    deleteCandidate = nil
                }
            } message: { event in
                Text("Delete \(event.title.lowercased()) from \(timestampText(for: event))?")
            }
        } else {
            ProgressView("Loading timeline…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Timeline")
        }
    }

    private func timelineContent(
        timeline: TimelineScreenState,
        canManageEvents: Bool
    ) -> some View {
        List {
            Section {
                HStack {
                    Button {
                        model.showPreviousTimelineDay()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityIdentifier("timeline-previous-day-button")

                    Spacer()

                    Text(timeline.dayTitle)
                        .font(.headline)
                        .accessibilityIdentifier("timeline-day-title")

                    Spacer()

                    Button {
                        model.showNextTimelineDay()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!timeline.canMoveToNextDay)
                    .accessibilityIdentifier("timeline-next-day-button")
                }

                if timeline.showsJumpToToday {
                    Button("Today") {
                        model.jumpTimelineToToday()
                    }
                    .accessibilityIdentifier("timeline-jump-to-today-button")
                }
            }

            if let syncMessage = timeline.syncMessage {
                Section {
                    Text(syncMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("timeline-sync-message")
                }
            }

            Section("Events") {
                if timeline.rows.isEmpty {
                    ContentUnavailableView(
                        timeline.emptyStateTitle,
                        systemImage: "clock",
                        description: Text(timeline.emptyStateMessage)
                    )
                    .accessibilityIdentifier("timeline-empty-state")
                } else {
                    ForEach(timeline.rows) { event in
                        timelineRow(
                            for: event,
                            canManageEvents: canManageEvents
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func timelineRow(
        for event: TimelineEventRowViewState,
        canManageEvents: Bool
    ) -> some View {
        let content = timelineRowContent(for: event)

        if canManageEvents {
            Button {
                activeEvent = event
            } label: {
                content
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("timeline-event-\(event.id.uuidString)")
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button(leadingActionTitle(for: event)) {
                    activeEvent = event
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteCandidate = event
                }
            }
        } else {
            content
                .accessibilityIdentifier("timeline-event-\(event.id.uuidString)")
        }
    }

    private func timelineRowContent(
        for event: TimelineEventRowViewState
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let gapFromPreviousText = event.gapFromPreviousText {
                Text(gapFromPreviousText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("timeline-gap-\(event.id.uuidString)")
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)

                    Text(event.detailText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let overlapText = event.overlapText {
                        Text(overlapText)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("timeline-overlap-\(event.id.uuidString)")
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.timeText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)

                    if let secondaryTimeText = event.secondaryTimeText {
                        Text(secondaryTimeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func leadingActionTitle(
        for event: TimelineEventRowViewState
    ) -> String {
        switch event.actionPayload {
        case .endSleep:
            return "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            return "Edit"
        }
    }

    @ViewBuilder
    private func eventSheet(
        for event: TimelineEventRowViewState,
        canManageEvents: Bool
    ) -> some View {
        switch event.actionPayload {
        case let .editBreastFeed(durationMinutes, endTime, side):
            BreastFeedEditorSheetView(
                navigationTitle: "Edit Breast Feed",
                primaryActionTitle: "Update",
                initialDurationMinutes: durationMinutes,
                initialEndTime: endTime,
                initialSide: side
            ) { updatedDuration, updatedEndTime, updatedSide in
                let didSave = model.updateBreastFeed(
                    id: event.id,
                    durationMinutes: updatedDuration,
                    endTime: updatedEndTime,
                    side: updatedSide
                )
                if didSave {
                    activeEvent = nil
                }
                return didSave
            }
        case let .editBottleFeed(amountMilliliters, occurredAt, milkType):
            BottleFeedEditorSheetView(
                navigationTitle: "Edit Bottle Feed",
                primaryActionTitle: "Update",
                initialAmountMilliliters: amountMilliliters,
                initialOccurredAt: occurredAt,
                initialMilkType: milkType
            ) { updatedAmount, updatedOccurredAt, updatedMilkType in
                let didSave = model.updateBottleFeed(
                    id: event.id,
                    amountMilliliters: updatedAmount,
                    occurredAt: updatedOccurredAt,
                    milkType: updatedMilkType
                )
                if didSave {
                    activeEvent = nil
                }
                return didSave
            }
        case let .editNappy(type, occurredAt, intensity, pooColor):
            NappyEditorSheetView(
                navigationTitle: "Edit Nappy",
                primaryActionTitle: "Update",
                initialType: type,
                initialOccurredAt: occurredAt,
                initialIntensity: intensity,
                initialPooColor: pooColor
            ) { updatedType, updatedOccurredAt, updatedIntensity, updatedPooColor in
                let didSave = model.updateNappy(
                    id: event.id,
                    type: updatedType,
                    occurredAt: updatedOccurredAt,
                    intensity: updatedIntensity,
                    pooColor: updatedPooColor
                )
                if didSave {
                    activeEvent = nil
                }
                return didSave
            }
        case let .editSleep(startedAt, endedAt):
            SleepEditorSheetView(
                mode: .edit,
                initialStartedAt: startedAt,
                initialEndedAt: endedAt
            ) { updatedStartedAt, updatedEndedAt in
                guard let updatedEndedAt else {
                    return false
                }

                let didSave = model.updateSleep(
                    id: event.id,
                    startedAt: updatedStartedAt,
                    endedAt: updatedEndedAt
                )
                if didSave {
                    activeEvent = nil
                }
                return didSave
            }
        case let .endSleep(startedAt):
            SleepEditorSheetView(
                mode: .end,
                initialStartedAt: startedAt,
                initialEndedAt: defaultSleepEndTime(for: startedAt),
                saveAction: { updatedStartedAt, updatedEndedAt in
                    guard let updatedEndedAt else {
                        return false
                    }

                    let didSave = model.endSleep(
                        id: event.id,
                        startedAt: updatedStartedAt,
                        endedAt: updatedEndedAt
                    )
                    if didSave {
                        activeEvent = nil
                    }
                    return didSave
                },
                deleteAction: canManageEvents ? {
                    if model.deleteEvent(id: event.id) {
                        activeEvent = nil
                    }
                } : nil
            )
        }
    }

    private var deleteDialogTitle: String {
        guard let deleteCandidate else {
            return "Delete Event?"
        }

        return deleteDialogTitleText(for: deleteCandidate.kind)
    }

    private var deleteConfirmationIsPresented: Binding<Bool> {
        Binding(
            get: { deleteCandidate != nil },
            set: { isPresented in
                if !isPresented {
                    deleteCandidate = nil
                }
            }
        )
    }

    private func deleteDialogTitleText(
        for kind: BabyEventKind
    ) -> String {
        switch kind {
        case .breastFeed, .bottleFeed:
            return "Delete Feed?"
        case .sleep:
            return "Delete Sleep?"
        case .nappy:
            return "Delete Nappy?"
        }
    }

    private func deleteConfirmTitle(
        for event: TimelineEventRowViewState
    ) -> String {
        switch event.kind {
        case .breastFeed, .bottleFeed:
            return "Delete Feed"
        case .sleep:
            return "Delete Sleep"
        case .nappy:
            return "Delete Nappy"
        }
    }

    private func timestampText(
        for event: TimelineEventRowViewState
    ) -> String {
        guard let secondaryTimeText = event.secondaryTimeText else {
            return event.timeText
        }

        return "\(event.timeText) \(secondaryTimeText)"
    }

    private func defaultSleepEndTime(for startedAt: Date) -> Date {
        let now = Date()

        if startedAt > now {
            return now
        }

        return max(now, startedAt.addingTimeInterval(60))
    }
}
