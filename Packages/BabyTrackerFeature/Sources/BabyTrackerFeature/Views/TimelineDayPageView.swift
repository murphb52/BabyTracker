import BabyTrackerDomain
import SwiftUI

public struct TimelineDayPageView: View {
    let page: TimelineDayPageState
    let canManageEvents: Bool
    let openEvent: (TimelineEventBlockViewState) -> Void
    let deleteEvent: (TimelineEventBlockViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    private let minutesPerSlot: CGFloat = 5
    private let slotHeight: CGFloat = 4
    private let timeColumnWidth: CGFloat = 46
    private let laneSpacing: CGFloat = 6
    private let blockCornerRadius: CGFloat = 12

    private var hourRowHeight: CGFloat {
        slotsPerHour * slotHeight
    }

    private var slotsPerHour: CGFloat {
        60 / minutesPerSlot
    }

    public init(
        page: TimelineDayPageState,
        canManageEvents: Bool,
        openEvent: @escaping (TimelineEventBlockViewState) -> Void,
        deleteEvent: @escaping (TimelineEventBlockViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.page = page
        self.canManageEvents = canManageEvents
        self.openEvent = openEvent
        self.deleteEvent = deleteEvent
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if page.blocks.isEmpty {
                        emptyState(
                            title: page.emptyStateTitle,
                            message: page.emptyStateMessage
                        )
                    }

                    timelineCanvas()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            .accessibilityIdentifier("timeline-scroll-view")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                scrollToVisibleHour(using: proxy)
            }
            .onChange(of: page.date) { _, _ in
                scrollToVisibleHour(using: proxy)
            }
        }
    }

    private func emptyState(
        title: String,
        message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .accessibilityIdentifier("timeline-empty-state")
    }

    private func timelineCanvas() -> some View {
        GeometryReader { geometry in
            let contentWidth = max(geometry.size.width - timeColumnWidth - 12, 180)

            ZStack(alignment: .topLeading) {
                hourGrid()

                ForEach(page.blocks) { event in
                    timelineBlock(
                        for: event,
                        contentWidth: contentWidth
                    )
                }
            }
        }
        .frame(height: hourRowHeight * 24)
    }

    private func hourGrid() -> some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(alignment: .top, spacing: 12) {
                    Text(hourLabel(for: hour))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.top, 4)
                        .id(hourAnchorID(for: hour))

                    VStack(spacing: 0) {
                        ForEach(0..<Int(slotsPerHour), id: \.self) { slotIndex in
                            Rectangle()
                                .fill(backgroundColor(forHour: hour, slotIndex: slotIndex))
                                .frame(height: slotHeight)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: hourRowHeight)
                }
            }
        }
    }

    @ViewBuilder
    private func timelineBlock(
        for event: TimelineEventBlockViewState,
        contentWidth: CGFloat
    ) -> some View {
        let width = blockWidth(for: event, contentWidth: contentWidth)
        let height = blockHeight(for: event)
        let xOffset = blockXOffset(for: event, contentWidth: contentWidth)
        let yOffset = blockYOffset(for: event)
        let xPosition = timeColumnWidth + 12 + xOffset + (width / 2)
        let yPosition = yOffset + (height / 2)
        let isPendingDelete = pendingDeleteEvent?.id == event.id

        let baseBlock = timelineBlockContent(for: event)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(BabyEventStyle.timelineFillColor(for: event.kind))
            .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                    .stroke(BabyEventStyle.timelineBorderColor(for: event.kind), lineWidth: 1)
            )

        let interactiveBlock = Button {
            openEvent(event)
        } label: {
            baseBlock
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
        .accessibilityIdentifier("timeline-event-\(event.id.uuidString)")
        .accessibilityLabel("\(event.title), \(event.detailText), \(event.timeText)")
        .contextMenu {
            Button(primaryActionTitle(for: event)) {
                openEvent(event)
            }

            Button("Delete", role: .destructive) {
                deleteEvent(event)
            }
        }

        let blockView = ZStack(alignment: .bottomTrailing) {
            if canManageEvents {
                interactiveBlock
            } else {
                baseBlock
                    .accessibilityIdentifier("timeline-event-\(event.id.uuidString)")
                    .accessibilityLabel("\(event.title), \(event.detailText), \(event.timeText)")
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

        blockView
    }

    private func timelineBlockContent(
        for event: TimelineEventBlockViewState
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                    .font(.caption2.weight(.semibold))

                Text(primaryLineText(for: event))
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            if event.kind == .sleep {
                Text(event.timeText)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .opacity(0.9)
            }
        }
        .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: event.kind))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func primaryLineText(
        for event: TimelineEventBlockViewState
    ) -> String {
        guard event.detailText.isEmpty == false else {
            return event.title
        }

        return "\(event.title) • \(event.detailText)"
    }

    private func primaryActionTitle(
        for event: TimelineEventBlockViewState
    ) -> String {
        switch event.actionPayload {
        case .endSleep:
            "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            "Edit"
        }
    }

    private func blockWidth(
        for event: TimelineEventBlockViewState,
        contentWidth: CGFloat
    ) -> CGFloat {
        let laneCount = max(1, event.laneCount)
        let totalSpacing = CGFloat(laneCount - 1) * laneSpacing
        let width = (contentWidth - totalSpacing) / CGFloat(laneCount)

        return max(92, width)
    }

    private func blockHeight(
        for event: TimelineEventBlockViewState
    ) -> CGFloat {
        let minutes = max(10, event.endMinute - event.startMinute)
        let slotCount = ceil(CGFloat(minutes) / minutesPerSlot)
        return max(slotHeight * 2, slotCount * slotHeight)
    }

    private func blockXOffset(
        for event: TimelineEventBlockViewState,
        contentWidth: CGFloat
    ) -> CGFloat {
        let width = blockWidth(for: event, contentWidth: contentWidth)
        return CGFloat(event.laneIndex) * (width + laneSpacing)
    }

    private func blockYOffset(
        for event: TimelineEventBlockViewState
    ) -> CGFloat {
        let minuteOffset = CGFloat(event.startMinute)
        let slotOffset = floor(minuteOffset / minutesPerSlot)
        return slotOffset * slotHeight
    }

    private func backgroundColor(
        forHour hour: Int,
        slotIndex: Int
    ) -> Color {
        let baseColor: Color

        if Calendar.autoupdatingCurrent.isDateInToday(page.date),
           Calendar.autoupdatingCurrent.component(.hour, from: .now) == hour {
            baseColor = Color.accentColor.opacity(0.08)
        } else {
            baseColor = Color(.secondarySystemGroupedBackground)
        }

        if slotIndex == 0 {
            return baseColor.opacity(0.98)
        }

        if slotIndex % 3 == 0 {
            return baseColor.opacity(0.9)
        }

        return baseColor.opacity(0.72)
    }

    private func hourLabel(
        for hour: Int
    ) -> String {
        let components = DateComponents(hour: hour)
        let date = Calendar.autoupdatingCurrent.date(from: components) ?? .now
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    private func hourAnchorID(
        for hour: Int
    ) -> String {
        "timeline-hour-\(hour)"
    }

    private func scrollToVisibleHour(
        using proxy: ScrollViewProxy
    ) {
        guard Calendar.autoupdatingCurrent.isDateInToday(page.date) else {
            return
        }

        let currentHour = Calendar.autoupdatingCurrent.component(.hour, from: .now)
        DispatchQueue.main.async {
            proxy.scrollTo(hourAnchorID(for: currentHour), anchor: .top)
        }
    }
}

#Preview("Compact Day Timeline") {
    let now = Date()
    let calendar = Calendar.autoupdatingCurrent
    let startOfDay = calendar.startOfDay(for: now)

    let sleepStart = calendar.date(byAdding: .hour, value: 1, to: startOfDay) ?? startOfDay
    let sleepEnd = calendar.date(byAdding: .hour, value: 3, to: sleepStart) ?? sleepStart

    let bottleTime = calendar.date(byAdding: .hour, value: 9, to: startOfDay) ?? startOfDay
    let nappyTime = calendar.date(byAdding: .hour, value: 11, to: startOfDay) ?? startOfDay

    let sleepStartMinute = calendar.dateComponents([.hour, .minute], from: sleepStart).hour.map { ($0 * 60) + calendar.component(.minute, from: sleepStart) } ?? 0
    let sleepEndMinute = calendar.dateComponents([.hour, .minute], from: sleepEnd).hour.map { ($0 * 60) + calendar.component(.minute, from: sleepEnd) } ?? 120

    let bottleMinute = calendar.component(.hour, from: bottleTime) * 60 + calendar.component(.minute, from: bottleTime)
    let nappyMinute = calendar.component(.hour, from: nappyTime) * 60 + calendar.component(.minute, from: nappyTime)

    return TimelineDayPageView(
        page: TimelineDayPageState(
            date: now,
            dayTitle: "Today",
            shortWeekdayTitle: "Thu",
            isToday: true,
            blocks: [
                TimelineEventBlockViewState(
                    id: UUID(),
                    kind: .sleep,
                    title: "Sleep",
                    detailText: "2h 0m",
                    timeText: "1:00 AM - 3:00 AM",
                    compactText: "Sleep • 2h 0m",
                    startMinute: sleepStartMinute,
                    endMinute: sleepEndMinute,
                    laneIndex: 0,
                    laneCount: 1,
                    actionPayload: .editSleep(startedAt: sleepStart, endedAt: sleepEnd)
                ),
                TimelineEventBlockViewState(
                    id: UUID(),
                    kind: .bottleFeed,
                    title: "Bottle",
                    detailText: "120 ml",
                    timeText: "9:00 AM",
                    compactText: "Bottle • 120 ml",
                    startMinute: bottleMinute,
                    endMinute: bottleMinute + 10,
                    laneIndex: 0,
                    laneCount: 1,
                    actionPayload: .editBottleFeed(
                        amountMilliliters: 120,
                        occurredAt: bottleTime,
                        milkType: nil
                    )
                ),
                TimelineEventBlockViewState(
                    id: UUID(),
                    kind: .nappy,
                    title: "Nappy",
                    detailText: "Wet",
                    timeText: "11:00 AM",
                    compactText: "Nappy • Wet",
                    startMinute: nappyMinute,
                    endMinute: nappyMinute + 10,
                    laneIndex: 0,
                    laneCount: 1,
                    actionPayload: .editNappy(
                        type: .wet,
                        occurredAt: nappyTime,
                        peeVolume: nil,
                        pooVolume: nil,
                        pooColor: nil
                    )
                )
            ],
            emptyStateTitle: "No events yet",
            emptyStateMessage: "Log your first event to build your timeline."
        ),
        canManageEvents: true,
        openEvent: { _ in },
        deleteEvent: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
}
