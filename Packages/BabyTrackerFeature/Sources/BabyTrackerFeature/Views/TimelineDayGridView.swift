import BabyTrackerDomain
import SwiftUI

public struct TimelineDayGridView: View {
    let day: Date
    let grid: TimelineDayGridViewState
    let canManageEvents: Bool
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    private let timeColumnWidth: CGFloat = 48
    private let columnSpacing: CGFloat = 8
    private let slotHeight: CGFloat = 22

    public init(
        day: Date,
        grid: TimelineDayGridViewState,
        canManageEvents: Bool,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.day = day
        self.grid = grid
        self.canManageEvents = canManageEvents
        self.openItem = openItem
        self.deleteItem = deleteItem
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        VStack(spacing: 12) {
            headerRow

            GeometryReader { geometry in
                let columnWidth = max(
                    72,
                    (geometry.size.width - timeColumnWidth - (columnSpacing * CGFloat(max(0, grid.columns.count - 1)))) / CGFloat(max(1, grid.columns.count))
                )

                ZStack(alignment: .topLeading) {
                    slotGrid(columnWidth: columnWidth)

                    ForEach(Array(grid.columns.enumerated()), id: \.element.kind) { index, column in
                        ForEach(column.items) { item in
                            TimelineDayGridItemView(
                                item: item,
                                height: itemHeight(for: item),
                                canManageEvents: canManageEvents,
                                openItem: openItem,
                                deleteItem: deleteItem,
                                pendingDeleteEvent: pendingDeleteEvent,
                                confirmDelete: confirmDelete,
                                cancelDelete: cancelDelete
                            )
                            .frame(width: columnWidth, height: itemHeight(for: item))
                            .offset(
                                x: xOffset(for: index, columnWidth: columnWidth),
                                y: CGFloat(item.startSlotIndex) * slotHeight + 2
                            )
                        }
                    }
                }
            }
            .frame(height: CGFloat(slotCount) * slotHeight)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .bottom, spacing: columnSpacing) {
            Color.clear
                .frame(width: timeColumnWidth, height: 1)

            ForEach(grid.columns, id: \.kind) { column in
                Text(column.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
            }
        }
    }

    private func slotGrid(columnWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<slotCount, id: \.self) { slotIndex in
                HStack(spacing: columnSpacing) {
                    if slotIndex.isMultiple(of: slotsPerHour) {
                        Text(hourLabel(for: slotIndex / slotsPerHour))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: timeColumnWidth, alignment: .trailing)
                            .id(hourAnchorID(for: slotIndex / slotsPerHour))
                        Color.clear
                            .frame(width: timeColumnWidth)
                    }

                    ForEach(Array(grid.columns.enumerated()), id: \.offset) { index, column in
                        slotCell(
                            column: column,
                            slotIndex: slotIndex,
                            isHourBoundary: slotIndex.isMultiple(of: slotsPerHour)
                        )
                        .frame(width: columnWidth, height: slotHeight)
                    }
                }
            }
        }
    }

    private func slotCell(
        column: TimelineDayGridColumnViewState,
        slotIndex: Int,
        isHourBoundary: Bool
    ) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    slotIndex.isMultiple(of: slotsPerHour)
                        ? Color(.secondarySystemGroupedBackground)
                        : Color(.tertiarySystemGroupedBackground)
                )

            Rectangle()
                .fill(isHourBoundary ? Color(.separator) : Color(.separator).opacity(0.25))
                .frame(height: 1)
        }
    }

    private var slotCount: Int {
        (24 * 60) / grid.slotMinutes
    }

    private var slotsPerHour: Int {
        max(1, 60 / grid.slotMinutes)
    }

    private func xOffset(for columnIndex: Int, columnWidth: CGFloat) -> CGFloat {
        timeColumnWidth + CGFloat(columnIndex) * (columnWidth + columnSpacing)
    }

    private func itemHeight(for item: TimelineDayGridItemViewState) -> CGFloat {
        max(
            slotHeight - 4,
            (CGFloat(item.endSlotIndex - item.startSlotIndex) * slotHeight) - 4
        )
    }

    private func hourLabel(for hour: Int) -> String {
        let date = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: hour, to: day) ?? day
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
    }

    private func hourAnchorID(for hour: Int) -> String {
        "timeline-day-grid-hour-\(hour)"
    }
}

#Preview("Empty Columns") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.emptyGrid,
            canManageEvents: false,
            openItem: { _ in },
            deleteItem: { _ in },
            pendingDeleteEvent: nil,
            confirmDelete: {},
            cancelDelete: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mixed Events") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.mixedGrid,
            canManageEvents: true,
            openItem: { _ in },
            deleteItem: { _ in },
            pendingDeleteEvent: nil,
            confirmDelete: {},
            cancelDelete: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Grouped Overlap") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.groupedGrid,
            canManageEvents: true,
            openItem: { _ in },
            deleteItem: { _ in },
            pendingDeleteEvent: nil,
            confirmDelete: {},
            cancelDelete: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

private enum TimelineDayGridPreviewFactory {
    static let day = Calendar.autoupdatingCurrent.startOfDay(for: .now)

    static let emptyGrid = TimelineDayGridViewState(
        slotMinutes: 15,
        columns: [
            TimelineDayGridColumnViewState(kind: .sleep, title: "Sleep", items: []),
            TimelineDayGridColumnViewState(kind: .nappy, title: "Nappy", items: []),
            TimelineDayGridColumnViewState(kind: .bottleFeed, title: "Bottle", items: []),
            TimelineDayGridColumnViewState(kind: .breastFeed, title: "Breast", items: [])
        ]
    )

    static let mixedGrid = TimelineDayGridViewState(
        slotMinutes: 15,
        columns: [
            TimelineDayGridColumnViewState(
                kind: .sleep,
                title: "Sleep",
                items: [
                    item(
                        id: "sleep-1",
                        kind: TimelineDayGridColumnKind.sleep,
                        startSlotIndex: 4,
                        endSlotIndex: 16,
                        title: "Sleep",
                        detailText: "180 min",
                        timeText: "01:00-04:00",
                        payloads: [.editSleep(startedAt: day, endedAt: day)]
                    )
                ]
            ),
            TimelineDayGridColumnViewState(
                kind: .nappy,
                title: "Nappy",
                items: [
                    item(
                        id: "nappy-1",
                        kind: TimelineDayGridColumnKind.nappy,
                        startSlotIndex: 28,
                        endSlotIndex: 29,
                        title: "Nappy",
                        detailText: "Pee",
                        timeText: "07:00",
                        payloads: [
                            EventActionPayload.editNappy(
                                type: .wee,
                                occurredAt: day,
                                peeVolume: nil,
                                pooVolume: nil,
                                pooColor: nil
                            )
                        ]
                    )
                ]
            ),
            TimelineDayGridColumnViewState(
                kind: .bottleFeed,
                title: "Bottle",
                items: [
                    item(
                        id: "bottle-1",
                        kind: TimelineDayGridColumnKind.bottleFeed,
                        startSlotIndex: 36,
                        endSlotIndex: 37,
                        title: "Bottle Feed",
                        detailText: "120 ml",
                        timeText: "09:00",
                        payloads: [
                            EventActionPayload.editBottleFeed(
                                amountMilliliters: 120,
                                occurredAt: day,
                                milkType: .formula
                            )
                        ]
                    )
                ]
            ),
            TimelineDayGridColumnViewState(
                kind: .breastFeed,
                title: "Breast",
                items: [
                    item(
                        id: "breast-1",
                        kind: TimelineDayGridColumnKind.breastFeed,
                        startSlotIndex: 42,
                        endSlotIndex: 46,
                        title: "Breast Feed",
                        detailText: "25 min",
                        timeText: "10:30-11:30",
                        payloads: [
                            EventActionPayload.editBreastFeed(
                                durationMinutes: 25,
                                endTime: day,
                                side: .left,
                                leftDurationSeconds: nil,
                                rightDurationSeconds: nil
                            )
                        ]
                    )
                ]
            )
        ]
    )

    static let groupedGrid = TimelineDayGridViewState(
        slotMinutes: 15,
        columns: [
            TimelineDayGridColumnViewState(
                kind: .sleep,
                title: "Sleep",
                items: [
                    item(
                        id: "sleep-2",
                        kind: TimelineDayGridColumnKind.sleep,
                        startSlotIndex: 52,
                        endSlotIndex: 68,
                        title: "Sleep",
                        detailText: "240 min",
                        timeText: "13:00-17:00",
                        payloads: [
                            EventActionPayload.editSleep(
                                startedAt: day,
                                endedAt: day
                            )
                        ]
                    )
                ]
            ),
            TimelineDayGridColumnViewState(kind: .nappy, title: "Nappy", items: []),
            TimelineDayGridColumnViewState(kind: .bottleFeed, title: "Bottle", items: []),
            TimelineDayGridColumnViewState(
                kind: .breastFeed,
                title: "Breast",
                items: [
                    TimelineDayGridItemViewState(
                        id: "grouped-breast",
                        columnKind: .breastFeed,
                        startSlotIndex: 34,
                        endSlotIndex: 40,
                        eventIDs: [UUID(), UUID(), UUID()],
                        count: 3,
                        title: "3 events",
                        detailText: "Breast Feed, Bottle Feed",
                        timeText: "08:30-10:00",
                        actionPayloads: [
                            EventActionPayload.editBreastFeed(durationMinutes: 10, endTime: day, side: .left, leftDurationSeconds: nil, rightDurationSeconds: nil),
                            EventActionPayload.editBreastFeed(durationMinutes: 14, endTime: day, side: .right, leftDurationSeconds: nil, rightDurationSeconds: nil),
                            EventActionPayload.editBreastFeed(durationMinutes: 12, endTime: day, side: nil, leftDurationSeconds: nil, rightDurationSeconds: nil)
                        ]
                    )
                ]
            )
        ]
    )

    private static func item(
        id: String,
        kind: TimelineDayGridColumnKind,
        startSlotIndex: Int,
        endSlotIndex: Int,
        title: String,
        detailText: String,
        timeText: String,
        payloads: [EventActionPayload]
    ) -> TimelineDayGridItemViewState {
        TimelineDayGridItemViewState(
            id: id,
            columnKind: kind,
            startSlotIndex: startSlotIndex,
            endSlotIndex: endSlotIndex,
            eventIDs: [UUID()],
            count: 1,
            title: title,
            detailText: detailText,
            timeText: timeText,
            actionPayloads: payloads
        )
    }
}
