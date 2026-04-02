import BabyTrackerDomain
import SwiftUI

public struct TimelineDayGridView: View {
    let pages: [TimelineDayPageState]
    let selectedDay: Date
    let canManageEvents: Bool
    let openEvent: (TimelineEventBlockViewState) -> Void
    let deleteEvent: (TimelineEventBlockViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    @State private var leadingColumnID: Date?

    private let hourRowHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 46
    private let columnSpacing: CGFloat = 8
    private let dayHeaderHeight: CGFloat = 44
    private let blockCornerRadius: CGFloat = 12
    private let laneSpacing: CGFloat = 4

    public init(
        pages: [TimelineDayPageState],
        selectedDay: Date,
        canManageEvents: Bool,
        openEvent: @escaping (TimelineEventBlockViewState) -> Void,
        deleteEvent: @escaping (TimelineEventBlockViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.pages = pages
        self.selectedDay = selectedDay
        self.canManageEvents = canManageEvents
        self.openEvent = openEvent
        self.deleteEvent = deleteEvent
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        GeometryReader { geometry in
            let columnWidth = dynamicColumnWidth(availableWidth: geometry.size.width)

            VStack(spacing: 0) {
                dayHeaderRow(columnWidth: columnWidth)

                ScrollViewReader { verticalProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 0) {
                            hourAxis()
                                .frame(width: timeColumnWidth)

                            ScrollViewReader { columnProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(alignment: .top, spacing: columnSpacing) {
                                        ForEach(pages) { page in
                                            dayColumn(
                                                page: page,
                                                columnWidth: columnWidth
                                            )
                                            .frame(width: columnWidth, height: hourRowHeight * 24)
                                            .id(page.date)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .scrollTargetLayout()
                                }
                                .scrollPosition(id: $leadingColumnID)
                                .onAppear {
                                    scrollToSelectedDay(using: columnProxy)
                                }
                                .onChange(of: selectedDay) { _, _ in
                                    scrollToSelectedDay(using: columnProxy)
                                }
                            }
                        }
                        .frame(height: hourRowHeight * 24)
                        .id("timeline-grid-content")
                    }
                    .onAppear {
                        scrollToCurrentHour(using: verticalProxy)
                    }
                    .onChange(of: selectedDay) { _, _ in
                        scrollToCurrentHour(using: verticalProxy)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Day Header Row

    private func dayHeaderRow(columnWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: timeColumnWidth + 8)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: columnSpacing) {
                    ForEach(pages) { page in
                        dayHeaderCell(page: page)
                            .frame(width: columnWidth)
                    }
                }
                .padding(.horizontal, 8)
            }
            .allowsHitTesting(false)
        }
        .frame(height: dayHeaderHeight)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) { Divider() }
    }

    private func dayHeaderCell(page: TimelineDayPageState) -> some View {
        let isSelected = Calendar.autoupdatingCurrent.isDate(page.date, inSameDayAs: selectedDay)

        return VStack(spacing: 2) {
            Text(page.shortWeekdayTitle)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(page.dayNumberTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    page.isToday ? Color.accentColor :
                    isSelected ? Color.primary :
                    Color.primary
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isSelected ?
                        Color.accentColor.opacity(0.12) :
                        Color.clear
                )
        )
    }

    // MARK: - Hour Axis

    private func hourAxis() -> some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(hourLabel(for: hour))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: hourRowHeight)
                    .padding(.trailing, 6)
                    .padding(.top, 6)
                    .id(hourAnchorID(for: hour))
            }
        }
    }

    // MARK: - Day Column

    private func dayColumn(
        page: TimelineDayPageState,
        columnWidth: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            columnBackground(page: page)

            ForEach(page.blocks) { block in
                columnBlock(
                    block: block,
                    columnWidth: columnWidth
                )
            }
        }
    }

    private func columnBackground(page: TimelineDayPageState) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(columnBackgroundColor(page: page, hour: hour))

                    Rectangle()
                        .fill(Color(.separator).opacity(0.4))
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: hourRowHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }

    private func columnBackgroundColor(
        page: TimelineDayPageState,
        hour: Int
    ) -> Color {
        guard page.isToday,
              Calendar.autoupdatingCurrent.component(.hour, from: .now) == hour else {
            return Color(.secondarySystemGroupedBackground)
        }

        return Color.accentColor.opacity(0.10)
    }

    // MARK: - Event Blocks

    @ViewBuilder
    private func columnBlock(
        block: TimelineEventBlockViewState,
        columnWidth: CGFloat
    ) -> some View {
        let width = blockWidth(for: block, columnWidth: columnWidth)
        let height = blockHeight(for: block)
        let xOffset = blockXOffset(for: block, columnWidth: columnWidth)
        let yOffset = blockYOffset(for: block)
        let xPosition = xOffset + (width / 2)
        let yPosition = yOffset + (height / 2)
        let isPendingDelete = pendingDeleteEvent?.id == block.id

        let baseBlock = blockContent(for: block, height: height)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(BabyEventStyle.timelineFillColor(for: block.kind))
            .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                    .stroke(BabyEventStyle.timelineBorderColor(for: block.kind), lineWidth: 1)
            )

        let interactiveBlock = Button {
            openEvent(block)
        } label: {
            baseBlock
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
        .accessibilityIdentifier("timeline-event-\(block.id.uuidString)")
        .accessibilityLabel("\(block.title), \(block.detailText), \(block.timeText)")
        .contextMenu {
            Button(primaryActionTitle(for: block)) {
                openEvent(block)
            }

            Button("Delete", role: .destructive) {
                deleteEvent(block)
            }
        }

        ZStack(alignment: .bottomTrailing) {
            if canManageEvents {
                interactiveBlock
            } else {
                baseBlock
                    .accessibilityIdentifier("timeline-event-\(block.id.uuidString)")
                    .accessibilityLabel("\(block.title), \(block.detailText), \(block.timeText)")
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
        .frame(width: width, height: height, alignment: .topLeading)
        .position(x: xPosition, y: yPosition)
        .zIndex(isPendingDelete ? 2 : 1)
    }

    @ViewBuilder
    private func blockContent(
        for block: TimelineEventBlockViewState,
        height: CGFloat
    ) -> some View {
        if block.kind == .sleep, height > 56 {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: BabyEventStyle.systemImage(for: block.kind))
                        .font(.caption2.weight(.semibold))

                    Text(block.title)
                        .font(height > 72 ? .footnote.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                }

                Text(block.detailText)
                    .font(.caption2)
                    .lineLimit(height > 84 ? 2 : 1)
                    .minimumScaleFactor(0.78)
                    .opacity(0.94)

                if height > 86 {
                    Text(block.timeText)
                        .font(.caption2.weight(.medium))
                        .opacity(0.85)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: block.kind))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: BabyEventStyle.systemImage(for: block.kind))
                        .font(.caption2.weight(.semibold))

                    Text(block.compactText)
                        .font(height <= 44 ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                if height > 64 {
                    Text(block.timeText)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .opacity(0.85)
                }
            }
            .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: block.kind))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Layout Helpers

    private func dynamicColumnWidth(availableWidth: CGFloat) -> CGFloat {
        let usableWidth = availableWidth - timeColumnWidth - 16
        let minimumColumnWidth: CGFloat = 72
        let idealColumnsVisible: CGFloat = availableWidth > 500 ? 7 : 3.5
        let calculatedWidth = (usableWidth - columnSpacing * (idealColumnsVisible - 1)) / idealColumnsVisible

        return max(minimumColumnWidth, calculatedWidth)
    }

    private func blockWidth(
        for block: TimelineEventBlockViewState,
        columnWidth: CGFloat
    ) -> CGFloat {
        let laneCount = max(1, block.laneCount)
        let totalSpacing = CGFloat(laneCount - 1) * laneSpacing
        let width = (columnWidth - totalSpacing) / CGFloat(laneCount)

        return max(44, width)
    }

    private func blockHeight(for block: TimelineEventBlockViewState) -> CGFloat {
        let minutes = max(20, block.endMinute - block.startMinute)
        return max(28, CGFloat(minutes) * hourRowHeight / 60)
    }

    private func blockXOffset(
        for block: TimelineEventBlockViewState,
        columnWidth: CGFloat
    ) -> CGFloat {
        let width = blockWidth(for: block, columnWidth: columnWidth)
        return CGFloat(block.laneIndex) * (width + laneSpacing)
    }

    private func blockYOffset(for block: TimelineEventBlockViewState) -> CGFloat {
        CGFloat(block.startMinute) * hourRowHeight / 60
    }

    private func primaryActionTitle(for block: TimelineEventBlockViewState) -> String {
        switch block.actionPayload {
        case .endSleep:
            "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            "Edit"
        }
    }

    // MARK: - Formatting

    private func hourLabel(for hour: Int) -> String {
        let components = DateComponents(hour: hour)
        let date = Calendar.autoupdatingCurrent.date(from: components) ?? .now
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    private func hourAnchorID(for hour: Int) -> String {
        "grid-hour-\(hour)"
    }

    // MARK: - Scroll Helpers

    private func scrollToSelectedDay(using proxy: ScrollViewProxy) {
        guard let target = pages.first(where: {
            Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: selectedDay)
        }) else { return }

        DispatchQueue.main.async {
            proxy.scrollTo(target.date, anchor: .center)
        }
    }

    private func scrollToCurrentHour(using proxy: ScrollViewProxy) {
        let hour: Int
        if pages.contains(where: { Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: selectedDay) && $0.isToday }) {
            hour = Calendar.autoupdatingCurrent.component(.hour, from: .now)
        } else {
            hour = 7
        }

        DispatchQueue.main.async {
            proxy.scrollTo(hourAnchorID(for: hour), anchor: .top)
        }
    }
}

#Preview {
    let today = Date()
    let calendar = Calendar.autoupdatingCurrent

    let pages: [TimelineDayPageState] = (0..<7).compactMap { offset in
        calendar.date(byAdding: .day, value: offset - 3, to: today).map { date in
            TimelineDayPageState(
                date: date,
                dayTitle: date.formatted(.dateTime.weekday(.wide)),
                shortWeekdayTitle: date.formatted(.dateTime.weekday(.abbreviated)),
                dayNumberTitle: date.formatted(.dateTime.day()),
                isToday: calendar.isDateInToday(date),
                blocks: [],
                emptyStateTitle: "No events",
                emptyStateMessage: "Nothing logged."
            )
        }
    }

    TimelineDayGridView(
        pages: pages,
        selectedDay: today,
        canManageEvents: true,
        openEvent: { _ in },
        deleteEvent: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
}
