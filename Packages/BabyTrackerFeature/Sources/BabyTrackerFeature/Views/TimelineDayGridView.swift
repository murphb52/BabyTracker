import BabyTrackerDomain
import SwiftUI

public struct TimelineDayGridView: View {
    let day: Date
    let grid: TimelineDayGridViewState
    let availableWidth: CGFloat
    let canManageEvents: Bool
    @Binding var horizontalScrollOffset: CGFloat
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void

    @State private var bodyScrollPosition = ScrollPosition()

    public init(
        day: Date,
        grid: TimelineDayGridViewState,
        availableWidth: CGFloat,
        canManageEvents: Bool,
        horizontalScrollOffset: Binding<CGFloat>,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void
    ) {
        self.day = day
        self.grid = grid
        self.availableWidth = availableWidth
        self.canManageEvents = canManageEvents
        self._horizontalScrollOffset = horizontalScrollOffset
        self.openItem = openItem
        self.deleteItem = deleteItem
    }

    public var body: some View {
        let layout = TimelineDayGridLayout(
            availableWidth: availableWidth,
            columnCount: grid.columns.count
        )

        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal) {
                ZStack(alignment: .topLeading) {
                    slotGrid(layout: layout)

                    if isToday {
                        currentTimeIndicator(layout: layout)
                    }

                    ForEach(Array(grid.columns.enumerated()), id: \.element.kind) { index, column in
                        ForEach(column.items) { item in
                            TimelineDayGridItemView(
                                item: item,
                                height: itemHeight(for: item),
                                canManageEvents: canManageEvents,
                                openItem: openItem,
                                deleteItem: deleteItem
                            )
                            .frame(width: layout.columnWidth, height: itemHeight(for: item))
                            .offset(
                                x: xOffset(for: index, layout: layout),
                                y: CGFloat(item.startSlotIndex) * layout.slotHeight + layout.itemVerticalInset
                            )
                        }
                    }
                }
                .frame(width: layout.contentWidth, alignment: .leading)
            }
            .scrollPosition($bodyScrollPosition)
            .defaultScrollAnchor(.leading)
            .accessibilityIdentifier("timeline-horizontal-scroll-view")
            .onAppear {
                bodyScrollPosition.scrollTo(x: horizontalScrollOffset)
            }
            .onChange(of: horizontalScrollOffset) { _, newValue in
                bodyScrollPosition.scrollTo(x: newValue)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.x
            } action: { _, newValue in
                guard abs(horizontalScrollOffset - newValue) > 0.5 else {
                    return
                }

                horizontalScrollOffset = newValue
            }
            .padding(.leading, layout.timeColumnWidth + layout.columnSpacing)

            timeColumn(layout: layout)
                .background(Color(.systemGroupedBackground))
        }
        .frame(height: CGFloat(slotCount) * layout.slotHeight)
    }

    private func timeColumn(layout: TimelineDayGridLayout) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<slotCount, id: \.self) { slotIndex in
                ZStack(alignment: .topTrailing) {
                    Rectangle()
                        .fill(Color(.systemGroupedBackground))

                    if slotIndex.isMultiple(of: slotsPerHour) {
                        Text(hourLabel(for: slotIndex / slotsPerHour))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(width: layout.timeColumnWidth, alignment: .trailing)
                            .id(hourAnchorID(for: slotIndex / slotsPerHour))
                    }
                }
                .frame(width: layout.timeColumnWidth, height: layout.slotHeight)
                .overlay(alignment: .topTrailing) {
                    Rectangle()
                        .fill(slotIndex.isMultiple(of: slotsPerHour) ? Color(.separator) : Color(.separator).opacity(0.25))
                        .frame(height: 1)
                }
                .overlay(alignment: .topLeading) {
                    if slotIndex.isMultiple(of: slotsPerHour) {
                        Color.clear
                            .frame(width: 1, height: layout.initialScrollBottomOffset)
                            .id(initialScrollAnchorID(for: slotIndex / slotsPerHour))
                    }
                }
            }
        }
    }

    private func slotGrid(layout: TimelineDayGridLayout) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<slotCount, id: \.self) { slotIndex in
                HStack(spacing: layout.columnSpacing) {
                    ForEach(grid.columns, id: \.kind) { column in
                        slotCell(
                            slotIndex: slotIndex,
                            isHourBoundary: slotIndex.isMultiple(of: slotsPerHour)
                        )
                        .frame(width: layout.columnWidth, height: layout.slotHeight)
                        .id("\(column.kind.rawValue)-slot-\(slotIndex)")
                    }
                }
            }
        }
    }

    private func slotCell(
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

    private func currentTimeIndicator(layout: TimelineDayGridLayout) -> some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            Rectangle()
                .fill(Color.red)
                .frame(width: indicatorWidth(layout: layout), height: 1)
                .offset(
                    x: 0,
                    y: yOffsetForCurrentTime(at: context.date)
                )
                .accessibilityHidden(true)
        }
    }

    private var slotCount: Int {
        (24 * 60) / grid.slotMinutes
    }

    private var slotsPerHour: Int {
        max(1, 60 / grid.slotMinutes)
    }

    private func xOffset(for columnIndex: Int, layout: TimelineDayGridLayout) -> CGFloat {
        CGFloat(columnIndex) * (layout.columnWidth + layout.columnSpacing)
    }

    private func indicatorWidth(layout: TimelineDayGridLayout) -> CGFloat {
        (layout.columnWidth * CGFloat(grid.columns.count)) + (layout.columnSpacing * CGFloat(max(0, grid.columns.count - 1)))
    }

    private func yOffsetForCurrentTime(at date: Date) -> CGFloat {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = max(0, (components.hour ?? 0) * 60 + (components.minute ?? 0))
        let clampedMinutes = min(24 * 60, currentMinutes)
        let slotsFromStart = CGFloat(clampedMinutes) / CGFloat(grid.slotMinutes)
        return min(
            CGFloat(slotCount) * TimelineDayGridLayout.slotHeight,
            slotsFromStart * TimelineDayGridLayout.slotHeight
        )
    }

    private func itemHeight(for item: TimelineDayGridItemViewState) -> CGFloat {
        max(
            TimelineDayGridLayout.slotHeight - (TimelineDayGridLayout.itemVerticalInset * 2),
            (CGFloat(item.endSlotIndex - item.startSlotIndex) * TimelineDayGridLayout.slotHeight) - (TimelineDayGridLayout.itemVerticalInset * 2)
        )
    }

    private func hourLabel(for hour: Int) -> String {
        let date = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: hour, to: day) ?? day
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)))
    }

    private func hourAnchorID(for hour: Int) -> String {
        "timeline-day-grid-hour-\(hour)"
    }

    private func initialScrollAnchorID(for hour: Int) -> String {
        "timeline-day-grid-hour-offset-\(hour)"
    }

    private var isToday: Bool {
        Calendar.autoupdatingCurrent.isDateInToday(day)
    }
}

struct TimelineDayGridHeaderView: View {
    let grid: TimelineDayGridViewState
    let availableWidth: CGFloat
    @Binding var horizontalScrollOffset: CGFloat

    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        let layout = TimelineDayGridLayout(
            availableWidth: availableWidth,
            columnCount: grid.columns.count
        )

        HStack(alignment: .bottom, spacing: layout.columnSpacing) {
            Color.clear
                .frame(width: layout.timeColumnWidth, height: 1)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: layout.columnSpacing) {
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
                        .frame(width: layout.columnWidth)
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
                .frame(width: layout.contentWidth, alignment: .leading)
            }
            .scrollPosition($scrollPosition)
            .defaultScrollAnchor(.leading)
            .accessibilityIdentifier("timeline-sticky-header")
            .onAppear {
                scrollPosition.scrollTo(x: horizontalScrollOffset)
            }
            .onChange(of: horizontalScrollOffset) { _, newValue in
                scrollPosition.scrollTo(x: newValue)
            }
        }
    }

    private func eventKind(for columnKind: TimelineDayGridColumnKind) -> BabyEventKind {
        switch columnKind {
        case .sleep:
            .sleep
        case .nappy:
            .nappy
        case .bath:
            .bath
        case .bottleFeed:
            .bottleFeed
        case .breastFeed:
            .breastFeed
        }
    }
}

private struct TimelineDayGridLayout {
    static let timeColumnWidth: CGFloat = 20
    static let columnSpacing: CGFloat = 8
    static let slotHeight: CGFloat = 30
    static let itemVerticalInset: CGFloat = 3
    static let initialScrollBottomOffset: CGFloat = 150
    static let minimumColumnWidth: CGFloat = 96

    let availableWidth: CGFloat
    let columnCount: Int

    var timeColumnWidth: CGFloat { Self.timeColumnWidth }
    var columnSpacing: CGFloat { Self.columnSpacing }
    var slotHeight: CGFloat { Self.slotHeight }
    var itemVerticalInset: CGFloat { Self.itemVerticalInset }
    var initialScrollBottomOffset: CGFloat { Self.initialScrollBottomOffset }

    var columnWidth: CGFloat {
        let visibleColumnCount = CGFloat(max(1, min(columnCount, 4)))
        let fittedWidth = (
            max(0, availableWidth - timeColumnWidth - columnSpacing)
            - (columnSpacing * CGFloat(max(0, columnCount - 1)))
        ) / visibleColumnCount
        return max(Self.minimumColumnWidth, fittedWidth)
    }

    var contentWidth: CGFloat {
        (columnWidth * CGFloat(columnCount)) + (columnSpacing * CGFloat(max(0, columnCount - 1)))
    }
}

#Preview("Empty Columns") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.emptyGrid,
            availableWidth: 360,
            canManageEvents: false,
            horizontalScrollOffset: .constant(0),
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
            availableWidth: 360,
            canManageEvents: true,
            horizontalScrollOffset: .constant(0),
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
            availableWidth: 360,
            canManageEvents: true,
            horizontalScrollOffset: .constant(0),
            openItem: { _ in },
            deleteItem: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Past Day (No Current Time Line)") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.previousDay,
            grid: TimelineDayGridPreviewFactory.mixedGrid,
            availableWidth: 360,
            canManageEvents: true,
            horizontalScrollOffset: .constant(0),
            openItem: { _ in },
            deleteItem: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Narrow Width Overflow") {
    ScrollView {
        TimelineDayGridView(
            day: TimelineDayGridPreviewFactory.day,
            grid: TimelineDayGridPreviewFactory.mixedGrid,
            availableWidth: 300,
            canManageEvents: true,
            horizontalScrollOffset: .constant(0),
            openItem: { _ in },
            deleteItem: { _ in }
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

private enum TimelineDayGridPreviewFactory {
    static let day = Calendar.autoupdatingCurrent.startOfDay(for: .now)
    static let previousDay = Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: day) ?? day

    static let emptyGrid = TimelineDayGridViewState(
        slotMinutes: 15,
        columns: [
            TimelineDayGridColumnViewState(kind: .sleep, title: "Sleep", items: []),
            TimelineDayGridColumnViewState(kind: .nappy, title: "Nappy", items: []),
            TimelineDayGridColumnViewState(kind: .bath, title: "Bath", items: []),
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
                kind: .bath,
                title: "Bath",
                items: [
                    item(
                        id: "bath-1",
                        kind: TimelineDayGridColumnKind.bath,
                        startSlotIndex: 32,
                        endSlotIndex: 33,
                        title: "Bath",
                        detailText: "Shampoo",
                        timeText: "",
                        payloads: [
                            EventActionPayload.editBath(
                                occurredAt: day,
                                usedShampoo: true,
                                usedSoap: false
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
                        title: "120 mL",
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
            TimelineDayGridColumnViewState(kind: .bath, title: "Bath", items: []),
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
