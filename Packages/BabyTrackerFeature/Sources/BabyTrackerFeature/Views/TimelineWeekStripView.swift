import BabyTrackerDomain
import SwiftUI

public struct TimelineWeekStripView: View {
    let columns: [TimelineStripDayColumnViewState]
    let selectedDay: Date
    let showDay: (Date) -> Void

    private let hourLabelWidth: CGFloat = 34
    private let minimumVisibleColumns: CGFloat = 7
    private let columnSpacing: CGFloat = 10

    public init(
        columns: [TimelineStripDayColumnViewState],
        selectedDay: Date,
        showDay: @escaping (Date) -> Void
    ) {
        self.columns = columns
        self.selectedDay = selectedDay
        self.showDay = showDay
    }

    public var body: some View {
        GeometryReader { geometry in
            let chartWidth = max(0, geometry.size.width - hourLabelWidth - 12)
            let minimumColumnWidth = max(
                28,
                (chartWidth - (columnSpacing * (minimumVisibleColumns - 1))) / minimumVisibleColumns
            )
            let chartHeight = max(280, geometry.size.height - 58)
            let slotHeight = max(0.5, chartHeight / CGFloat(max(1, slotCount)))

            HStack(alignment: .top, spacing: 0) {
                hourAxis(slotHeight: slotHeight)
                    .frame(width: hourLabelWidth)
                    .padding(.top, 28)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: columnSpacing) {
                            ForEach(columns) { column in
                                stripColumn(
                                    column,
                                    columnWidth: minimumColumnWidth,
                                    slotHeight: slotHeight
                                )
                                .id(column.id)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .padding(.top, 8)
                    }
                    .onAppear {
                        scrollToSelectedDay(using: proxy)
                    }
                    .onChange(of: selectedDay) { _, _ in
                        scrollToSelectedDay(using: proxy)
                    }
                }
            }
        }
    }

    private func stripColumn(
        _ column: TimelineStripDayColumnViewState,
        columnWidth: CGFloat,
        slotHeight: CGFloat
    ) -> some View {
        let isSelected = Calendar.autoupdatingCurrent.isDate(column.date, inSameDayAs: selectedDay)

        return Button {
            showDay(column.date)
        } label: {
            VStack(spacing: 6) {
                VStack(spacing: 1) {
                    Text(column.shortWeekdayTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(column.dayNumberTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(column.isToday ? Color.accentColor : Color.primary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(column.slots.enumerated()), id: \.offset) { index, kind in
                        Rectangle()
                            .fill(slotColor(for: kind, slotIndex: index))
                            .frame(height: slotHeight)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: isSelected ? 1.5 : 1)
                }
            }
            .frame(width: columnWidth)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("timeline-strip-column-\(column.date.timeIntervalSince1970)")
    }

    private func hourAxis(slotHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(stride(from: 0, to: 24, by: 2)), id: \.self) { hour in
                Text(hourLabel(for: hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: slotHeight * CGFloat(slotsPerTwoHours))
            }
        }
    }

    private func slotColor(
        for kind: BabyEventKind?,
        slotIndex: Int
    ) -> Color {
        if let kind {
            return BabyEventStyle.timelineFillColor(for: kind)
        }

        if slotIndex % slotsPerTwoHours == 0 {
            return Color(.quaternaryLabel).opacity(0.16)
        }

        return Color(.clear)
    }

    private var slotCount: Int {
        columns.first?.slots.count ?? 0
    }

    private var slotsPerHour: Int {
        max(1, slotCount / 24)
    }

    private var slotsPerTwoHours: Int {
        max(1, slotsPerHour * 2)
    }

    private func hourLabel(for hour: Int) -> String {
        return hour < 10 ? "0\(hour)" : "\(hour)"
    }

    private func scrollToSelectedDay(
        using proxy: ScrollViewProxy
    ) {
        DispatchQueue.main.async {
            proxy.scrollTo(
                columns.first(where: { Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: selectedDay) })?.id,
                anchor: .center
            )
        }
    }
}
