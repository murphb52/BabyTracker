import SwiftUI

public struct TimelineDayGridGroupedEventsSheetView: View {
    let item: TimelineDayGridItemViewState
    let canManageEvents: Bool
    let openEvent: (EventCardViewState) -> Void

    public init(
        item: TimelineDayGridItemViewState,
        canManageEvents: Bool,
        openEvent: @escaping (EventCardViewState) -> Void
    ) {
        self.item = item
        self.canManageEvents = canManageEvents
        self.openEvent = openEvent
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.timeText)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    ForEach(item.groupedEntries) { entry in
                        Button {
                            openEvent(entry)
                        } label: {
                            EventCardView(event: entry)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canManageEvents)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    TimelineDayGridGroupedEventsSheetView(
        item: TimelineDayGridItemViewState(
            id: "grouped-sheet-preview",
            columnKind: .breastFeed,
            startSlotIndex: 34,
            endSlotIndex: 40,
            eventIDs: [UUID(), UUID()],
            count: 2,
            title: "2 events",
            detailText: "Multiple events",
            timeText: "08:30-10:00",
            actionPayloads: [
                EventActionPayload.editBreastFeed(
                    durationMinutes: 10,
                    endTime: .now,
                    side: .left,
                    leftDurationSeconds: nil,
                    rightDurationSeconds: nil
                ),
                EventActionPayload.editBottleFeed(
                    amountMilliliters: 120,
                    occurredAt: .now,
                    milkType: .formula
                )
            ],
            groupedEntries: [
                TimelineDayGridGroupedEventsSheetPreviewFactory.breastFeedEntry,
                TimelineDayGridGroupedEventsSheetPreviewFactory.bottleFeedEntry
            ]
        ),
        canManageEvents: true,
        openEvent: { _ in }
    )
}

private enum TimelineDayGridGroupedEventsSheetPreviewFactory {
    static let breastFeedEntry = EventCardViewState(
        id: UUID(),
        kind: .breastFeed,
        title: "Breast Feed",
        detailText: "10 min • Left",
        timestampText: "08:30-08:40",
        actionPayload: .editBreastFeed(
            durationMinutes: 10,
            endTime: .now,
            side: .left,
            leftDurationSeconds: nil,
            rightDurationSeconds: nil
        )
    )

    static let bottleFeedEntry = EventCardViewState(
        id: UUID(),
        kind: .bottleFeed,
        title: "Bottle Feed",
        detailText: "120 mL • Formula",
        timestampText: "09:00",
        actionPayload: .editBottleFeed(
            amountMilliliters: 120,
            occurredAt: .now,
            milkType: .formula
        )
    )
}
