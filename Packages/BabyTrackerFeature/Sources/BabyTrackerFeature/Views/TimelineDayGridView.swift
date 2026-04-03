import BabyTrackerDomain
import SwiftUI

public struct TimelineDayGridView: View {
    let day: Date
    let grid: TimelineDayGridViewState
    let canManageEvents: Bool
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void

    private let timeColumnWidth: CGFloat = 20
    private let columnSpacing: CGFloat = 8
    private let slotHeight: CGFloat = 30
    private let itemVerticalInset: CGFloat = 3

    public init(
        day: Date,
        grid: TimelineDayGridViewState,
        canManageEvents: Bool,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void
    ) {
        self.day = day
        self.grid = grid
        self.canManageEvents = canManageEvents
        self.openItem = openItem
        self.deleteItem = deleteItem
    }

    public var body: some View {
        VStack(spacing: 12) {
            headerRow

            GeometryReader { geometry in
                let columnWidth = max(
                    72,
                    (
                        geometry.size.width
                        - timeColumnWidth
                        - (columnSpacing * CGFloat(grid.columns.count))
                    ) / CGFloat(max(1, grid.columns.count))
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
                                deleteItem: deleteItem
                            )
                        .frame(width: columnWidth, height: itemHeight(for: item))
                        .offset(
                            x: xOffset(for: index, columnWidth: columnWidth),
                            y: CGFloat(item.startSlotIndex) * slotHeight + itemVerticalInset
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
                let kind = eventKind(for: column.kind)

                HStack(spacing: 6) {
                    Image(systemName: BabyEventStyle.systemImage(for: kind))
                        .font(.caption.weight(.semibold))

                    Text(column.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(BabyEventStyle.accentColor(for: kind))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BabyEventStyle.backgroundColor(for: kind))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            BabyEventStyle.accentColor(for: kind).opacity(0.35),
                            lineWidth: 1
                        )
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
                    } else {
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
            Rectangle()
                .fill(Color(.secondarySystemGroupedBackground))

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
        timeColumnWidth + columnSpacing + CGFloat(columnIndex) * (columnWidth + columnSpacing)
    }

    private func itemHeight(for item: TimelineDayGridItemViewState) -> CGFloat {
        max(
            slotHeight - (itemVerticalInset * 2),
            (CGFloat(item.endSlotIndex - item.startSlotIndex) * slotHeight) - (itemVerticalInset * 2)
        )
    }

    private func hourLabel(for hour: Int) -> String {
        let date = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: hour, to: day) ?? day
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
    }

    private func hourAnchorID(for hour: Int) -> String {
        "timeline-day-grid-hour-\(hour)"
    }

    private func eventKind(for columnKind: TimelineDayGridColumnKind) -> BabyEventKind {
        switch columnKind {
        case .sleep:
            .sleep
        case .nappy:
            .nappy
        case .bottleFeed:
            .bottleFeed
        case .breastFeed:
            .breastFeed
        }
    }
}

#Preview("Empty Columns") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.emptyGrid,
            canManageEvents: false,
            openItem: { _ in },
            deleteItem: { _ in }
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
            deleteItem: { _ in }
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
            deleteItem: { _ in }
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
                        title: "3h",
                        detailText: "01:00",
                        timeText: "04:00",
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
                        title: "Pee",
                        detailText: "",
                        timeText: "",
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
                        title: "120 ml",
                        detailText: "",
                        timeText: "",
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
                        title: "25 min",
                        detailText: "",
                        timeText: "",
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
                        title: "4h",
                        detailText: "13:00",
                        timeText: "17:00",
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
