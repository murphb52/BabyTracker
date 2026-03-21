import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct TimelineScreenView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let openEvent: (TimelineEventBlockViewState) -> Void
    let deleteEvent: (TimelineEventBlockViewState) -> Void

    @State private var showingDayPicker = false

    private let hourRowHeight: CGFloat = 72
    private let timeColumnWidth: CGFloat = 46
    private let laneSpacing: CGFloat = 6
    private let blockCornerRadius: CGFloat = 12

    var body: some View {
        timelineContent(
            timeline: profile.timeline,
            canManageEvents: profile.canManageEvents
        )
        .sheet(isPresented: $showingDayPicker) {
            dayPickerSheet
        }
    }

    private func timelineContent(
        timeline: TimelineScreenState,
        canManageEvents: Bool
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let syncMessage = timeline.syncMessage {
                        syncBanner(message: syncMessage)
                    }

                    if timeline.blocks.isEmpty {
                        emptyState(
                            title: timeline.emptyStateTitle,
                            message: timeline.emptyStateMessage
                        )
                    }

                    timelineCanvas(
                        for: timeline,
                        canManageEvents: canManageEvents
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            .accessibilityIdentifier("timeline-scroll-view")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .simultaneousGesture(daySwipeGesture)
            .safeAreaInset(edge: .top, spacing: 0) {
                pinnedDayNavigationHeader(for: timeline)
            }
            .onAppear {
                scrollToVisibleHour(for: timeline.selectedDay, using: proxy)
            }
            .onChange(of: timeline.selectedDay) { _, selectedDay in
                scrollToVisibleHour(for: selectedDay, using: proxy)
            }
        }
    }

    private func pinnedDayNavigationHeader(
        for timeline: TimelineScreenState
    ) -> some View {
        dayNavigationHeader(for: timeline)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.regularMaterial)
            .overlay(alignment: .bottom) {
                Divider()
            }
    }

    private func dayNavigationHeader(
        for timeline: TimelineScreenState
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    model.showPreviousTimelineDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("timeline-previous-day-button")

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeline.dayTitle)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1, reservesSpace: true)
                        .accessibilityIdentifier("timeline-day-title")
                }

                Spacer()

                Button {
                    showingDayPicker = true
                } label: {
                    Image(systemName: "calendar")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("timeline-day-picker-button")

                if timeline.showsJumpToToday {
                    Button("Today") {
                        model.jumpTimelineToToday()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("timeline-jump-to-today-button")
                }

                Button {
                    model.showNextTimelineDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.bordered)
                .disabled(!timeline.canMoveToNextDay)
                .accessibilityIdentifier("timeline-next-day-button")
            }
        }
    }

    private var dayPickerSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                DatePicker(
                    "Day",
                    selection: timelineDayBinding,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .accessibilityIdentifier("timeline-day-picker")
            }
            .padding(20)
            .navigationTitle("Choose Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") {
                        model.jumpTimelineToToday()
                        showingDayPicker = false
                    }
                    .accessibilityIdentifier("timeline-day-picker-today-button")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingDayPicker = false
                    }
                    .accessibilityIdentifier("timeline-day-picker-done-button")
                }
            }
        }
        .presentationDetents([.large])
    }

    private func syncBanner(message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .accessibilityIdentifier("timeline-sync-message")
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
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityIdentifier("timeline-empty-state")
    }

    private func timelineCanvas(
        for timeline: TimelineScreenState,
        canManageEvents: Bool
    ) -> some View {
        GeometryReader { geometry in
            let contentWidth = max(geometry.size.width - timeColumnWidth - 12, 180)

            ZStack(alignment: .topLeading) {
                hourGrid(for: timeline)

                ForEach(timeline.blocks) { event in
                    timelineBlock(
                        for: event,
                        contentWidth: contentWidth,
                        canManageEvents: canManageEvents
                    )
                }
            }
        }
        .frame(height: hourRowHeight * 24)
    }

    private func hourGrid(
        for timeline: TimelineScreenState
    ) -> some View {
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
                            .fill(backgroundColor(forHour: hour, selectedDay: timeline.selectedDay))

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
        contentWidth: CGFloat,
        canManageEvents: Bool
    ) -> some View {
        let width = blockWidth(for: event, contentWidth: contentWidth)
        let height = blockHeight(for: event)
        let xOffset = blockXOffset(for: event, contentWidth: contentWidth)
        let yOffset = blockYOffset(for: event)
        let xPosition = timeColumnWidth + 12 + xOffset + (width / 2)
        let yPosition = yOffset + (height / 2)
        let content = timelineBlockContent(for: event, height: height)

        if canManageEvents {
            Button {
                openEvent(event)
            } label: {
                content
            }
            .buttonStyle(.plain)
            .frame(width: width, height: height, alignment: .topLeading)
            .background(blockBackgroundColor(for: event.kind))
            .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                    .stroke(blockBorderColor(for: event.kind), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
            .position(x: xPosition, y: yPosition)
            .simultaneousGesture(
                TapGesture().onEnded {
                    openEvent(event)
                }
            )
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
        } else {
            content
                .frame(width: width, height: height, alignment: .topLeading)
                .background(blockBackgroundColor(for: event.kind))
                .clipShape(RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: blockCornerRadius, style: .continuous)
                        .stroke(blockBorderColor(for: event.kind), lineWidth: 1)
                )
                .position(x: xPosition, y: yPosition)
                .accessibilityIdentifier("timeline-event-\(event.id.uuidString)")
        }
    }

    private func timelineBlockContent(
        for event: TimelineEventBlockViewState,
        height: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: systemImageName(for: event.kind))
                    .font(.caption.weight(.semibold))

                if height > 28 {
                    Text(event.title)
                        .font(height > 44 ? .footnote.weight(.semibold) : .caption.weight(.semibold))
                        .lineLimit(1)
                }
            }

            if height > 46 {
                Text(event.detailText)
                    .font(.caption)
                    .lineLimit(height > 74 ? 2 : 1)
                    .opacity(0.92)
            }

            if height > 72 {
                Text(event.timeText)
                    .font(.caption2.weight(.medium))
                    .opacity(0.85)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private func primaryActionTitle(
        for event: TimelineEventBlockViewState
    ) -> String {
        switch event.actionPayload {
        case .endSleep:
            return "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            return "Edit"
        }
    }

    private func systemImageName(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            return "heart.text.square"
        case .bottleFeed:
            return "drop.circle"
        case .sleep:
            return "bed.double"
        case .nappy:
            return "checklist"
        }
    }

    private func blockWidth(
        for event: TimelineEventBlockViewState,
        contentWidth: CGFloat
    ) -> CGFloat {
        let laneCount = max(1, event.laneCount)
        let totalSpacing = CGFloat(laneCount - 1) * laneSpacing
        let width = (contentWidth - totalSpacing) / CGFloat(laneCount)

        return max(82, width)
    }

    private func blockHeight(
        for event: TimelineEventBlockViewState
    ) -> CGFloat {
        let minutes = max(20, event.endMinute - event.startMinute)
        return max(28, CGFloat(minutes) * hourRowHeight / 60)
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

    private var timelineDayBinding: Binding<Date> {
        Binding(
            get: { profile.timeline.selectedDay },
            set: { day in
                model.showTimelineDay(day)
            }
        )
    }

    private func blockBackgroundColor(
        for kind: BabyEventKind
    ) -> Color {
        switch kind {
        case .breastFeed:
            return Color(red: 0.87, green: 0.35, blue: 0.54)
        case .bottleFeed:
            return Color(red: 0.11, green: 0.59, blue: 0.62)
        case .sleep:
            return Color(red: 0.28, green: 0.36, blue: 0.80)
        case .nappy:
            return Color(red: 0.90, green: 0.50, blue: 0.19)
        }
    }

    private func blockBorderColor(
        for kind: BabyEventKind
    ) -> Color {
        blockBackgroundColor(for: kind).opacity(0.75)
    }

    private func backgroundColor(
        forHour hour: Int,
        selectedDay: Date
    ) -> Color {
        guard Calendar.autoupdatingCurrent.isDateInToday(selectedDay),
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
        for selectedDay: Date,
        using proxy: ScrollViewProxy
    ) {
        guard Calendar.autoupdatingCurrent.isDateInToday(selectedDay) else {
            return
        }

        let currentHour = Calendar.autoupdatingCurrent.component(.hour, from: .now)
        DispatchQueue.main.async {
            proxy.scrollTo(hourAnchorID(for: currentHour), anchor: .top)
        }
    }

    private var daySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { gesture in
                let horizontalDistance = gesture.translation.width
                let verticalDistance = gesture.translation.height

                guard abs(horizontalDistance) > abs(verticalDistance),
                      abs(horizontalDistance) > 44 else {
                    return
                }

                if horizontalDistance < 0 {
                    model.showNextTimelineDay()
                } else {
                    model.showPreviousTimelineDay()
                }
            }
    }
}
