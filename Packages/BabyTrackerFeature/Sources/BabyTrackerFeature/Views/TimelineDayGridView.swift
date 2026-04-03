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
