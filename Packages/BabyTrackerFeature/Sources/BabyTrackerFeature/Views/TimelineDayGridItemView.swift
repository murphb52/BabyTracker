import BabyTrackerDomain
import SwiftUI

public struct TimelineDayGridItemView: View {
    let item: TimelineDayGridItemViewState
    let height: CGFloat
    let canManageEvents: Bool
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    public init(
        item: TimelineDayGridItemViewState,
        height: CGFloat,
        canManageEvents: Bool,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.item = item
        self.height = height
        self.canManageEvents = canManageEvents
        self.openItem = openItem
        self.deleteItem = deleteItem
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        let isPendingDelete = pendingDeleteEvent?.id == item.primaryEventID
        let base = content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(BabyEventStyle.timelineFillColor(for: item.eventKind))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(BabyEventStyle.timelineBorderColor(for: item.eventKind), lineWidth: 1)
            )

        ZStack(alignment: .bottomTrailing) {
            if item.opensGroupedSheet || (canManageEvents && item.isInteractive) {
                Button {
                    openItem(item)
                } label: {
                    base
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .contextMenu {
                    if item.isInteractive {
                        Button("Edit") {
                            openItem(item)
                        }

                        Button("Delete", role: .destructive) {
                            deleteItem(item)
                        }
                    }
                }
            } else {
                base
            }

            if isPendingDelete, let pendingDeleteEvent {
                AnchoredDeletePromptView(
                    title: "Delete \(pendingDeleteEvent.title.lowercased())?",
                    confirmTitle: pendingDeleteEvent.confirmButtonTitle,
                    confirmAction: confirmDelete,
                    cancelAction: cancelDelete
                )
                .padding(8)
            }
        }
        .accessibilityIdentifier("timeline-day-grid-item-\(item.id)")
        .accessibilityLabel(accessibilityLabelText)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(height > 66 ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .lineLimit(1)

            if height > 52, !item.detailText.isEmpty {
                Text(item.detailText)
                    .font(.caption2)
                    .lineLimit(height > 92 ? 2 : 1)
            }

            if height > 78, !item.timeText.isEmpty {
                Text(item.timeText)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .opacity(0.85)
            }
        }
        .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: item.eventKind))
    }

    private var accessibilityLabelText: String {
        [item.title, item.detailText, item.timeText]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

#Preview("Sleep Block") {
    TimelineDayGridItemView(
        item: TimelineDayGridItemPreviewFactory.sleepItem,
        height: 124,
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
    .frame(width: 132, height: 124)
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Nappy Block") {
    TimelineDayGridItemView(
        item: TimelineDayGridItemPreviewFactory.nappyItem,
        height: 18,
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
    .frame(width: 132, height: 18)
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Grouped Block") {
    TimelineDayGridItemView(
        item: TimelineDayGridItemPreviewFactory.groupedItem,
        height: 72,
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
    .frame(width: 132, height: 72)
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Pending Delete") {
    TimelineDayGridItemView(
        item: TimelineDayGridItemPreviewFactory.deleteCandidateItem,
        height: 96,
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: EventDeleteCandidate(event: TimelineDayGridItemPreviewFactory.deleteCandidateItem),
        confirmDelete: {},
        cancelDelete: {}
    )
    .frame(width: 180, height: 140)
    .padding()
    .background(Color(.systemGroupedBackground))
}

private enum TimelineDayGridItemPreviewFactory {
    static let sleepItem = TimelineDayGridItemViewState(
        id: "sleep-preview",
        columnKind: .sleep,
        startSlotIndex: 4,
        endSlotIndex: 16,
        eventIDs: [UUID()],
        count: 1,
        title: "3h 15m",
        detailText: "01:00",
        timeText: "04:15",
        actionPayloads: [
            EventActionPayload.editSleep(startedAt: .now, endedAt: .now)
        ]
    )

    static let nappyItem = TimelineDayGridItemViewState(
        id: "nappy-preview",
        columnKind: .nappy,
        startSlotIndex: 28,
        endSlotIndex: 29,
        eventIDs: [UUID()],
        count: 1,
        title: "Pee",
        detailText: "",
        timeText: "",
        actionPayloads: [
            EventActionPayload.editNappy(
                type: .wee,
                occurredAt: .now,
                peeVolume: nil,
                pooVolume: nil,
                pooColor: nil
            )
        ]
    )

    static let groupedItem = TimelineDayGridItemViewState(
        id: "grouped-preview",
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
            EventActionPayload.editBreastFeed(
                durationMinutes: 12,
                endTime: .now,
                side: .right,
                leftDurationSeconds: nil,
                rightDurationSeconds: nil
            )
        ],
        groupedEntries: [
            TimelineDayGridItemPreviewFactory.groupedBreastFeedEntry,
            TimelineDayGridItemPreviewFactory.groupedBottleFeedEntry
        ]
    )

    static let deleteCandidateItem = TimelineDayGridItemViewState(
        id: "delete-preview",
        columnKind: .sleep,
        startSlotIndex: 52,
        endSlotIndex: 60,
        eventIDs: [UUID()],
        count: 1,
        title: "2h",
        detailText: "13:00",
        timeText: "15:00",
        actionPayloads: [
            EventActionPayload.editSleep(startedAt: .now, endedAt: .now)
        ]
    )

    static let groupedBreastFeedEntry = EventCardViewState(
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

    static let groupedBottleFeedEntry = EventCardViewState(
        id: UUID(),
        kind: .bottleFeed,
        title: "Bottle Feed",
        detailText: "120 ml • Formula",
        timestampText: "09:00",
        actionPayload: .editBottleFeed(
            amountMilliliters: 120,
            occurredAt: .now,
            milkType: .formula
        )
    )
}
