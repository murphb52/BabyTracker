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

    private let hourRowHeight: CGFloat = 72
    private let timeColumnWidth: CGFloat = 46
    private let laneSpacing: CGFloat = 6
    private let blockCornerRadius: CGFloat = 14

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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(width: timeColumnWidth, alignment: .trailing)
                        .padding(.top, 6)
                        .id(hourAnchorID(for: hour))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(backgroundColor(forHour: hour))

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

        let baseBlock = timelineBlockContent(for: event, height: height)
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

    @ViewBuilder
    private func timelineBlockContent(
        for event: TimelineEventBlockViewState,
        height: CGFloat
    ) -> some View {
        if event.kind == .sleep, height > 56 {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                        .font(.caption.weight(.semibold))

                    Text(event.title)
                        .font(height > 72 ? .footnote.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                }

                Text(event.detailText)
                    .font(.caption)
                    .lineLimit(height > 84 ? 2 : 1)
                    .minimumScaleFactor(0.78)
                    .opacity(0.94)

                if height > 86 {
                    Text(event.timeText)
                        .font(.caption2.weight(.medium))
                        .opacity(0.85)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: event.kind))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                        .font(.caption.weight(.semibold))

                    Text(event.compactText)
                        .font(height <= 48 ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                if height > 72 {
                    Text(event.timeText)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .opacity(0.85)
                }
            }
            .foregroundStyle(BabyEventStyle.timelineForegroundColor(for: event.kind))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
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
        let minutes = max(20, event.endMinute - event.startMinute)
        return max(36, CGFloat(minutes) * hourRowHeight / 60)
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
        CGFloat(event.startMinute) * hourRowHeight / 60
    }

    private func backgroundColor(
        forHour hour: Int
    ) -> Color {
        guard Calendar.autoupdatingCurrent.isDateInToday(page.date),
              Calendar.autoupdatingCurrent.component(.hour, from: .now) == hour else {
            return Color(.secondarySystemGroupedBackground)
        }

        return Color.accentColor.opacity(0.12)
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
