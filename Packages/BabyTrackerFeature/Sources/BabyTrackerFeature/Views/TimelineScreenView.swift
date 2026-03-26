import SwiftUI

public struct TimelineScreenView: View {
    let model: AppModel
    let profile: ChildProfileScreenState
    let openEvent: (TimelineEventBlockViewState) -> Void
    let deleteEvent: (TimelineEventBlockViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    @State private var showingDayPicker = false
    @State private var dragStartPageIndex: Int = 0

    public init(
        model: AppModel,
        profile: ChildProfileScreenState,
        openEvent: @escaping (TimelineEventBlockViewState) -> Void,
        deleteEvent: @escaping (TimelineEventBlockViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.model = model
        self.profile = profile
        self.openEvent = openEvent
        self.deleteEvent = deleteEvent
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        VStack(spacing: 0) {
            pinnedDayNavigationHeader(for: profile.timeline)

            if let syncMessage = profile.timeline.syncMessage {
                syncBanner(message: syncMessage)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            TabView(selection: timelinePageBinding) {
                ForEach(Array(profile.timeline.pages.enumerated()), id: \.offset) { index, page in
                    TimelineDayPageView(
                        page: page,
                        canManageEvents: profile.canManageEvents,
                        openEvent: openEvent,
                        deleteEvent: deleteEvent,
                        pendingDeleteEvent: pendingDeleteEvent,
                        confirmDelete: confirmDelete,
                        cancelDelete: cancelDelete
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { _ in
                        if dragStartPageIndex != profile.timeline.selectedPageIndex {
                            dragStartPageIndex = profile.timeline.selectedPageIndex
                        }
                    }
                    .onEnded { value in
                        let swipe = value.translation.width
                        if swipe > 60 && dragStartPageIndex == 0 {
                            model.showPreviousTimelineDay()
                        } else if swipe < -60 && dragStartPageIndex == profile.timeline.pages.count - 1 {
                            model.showNextTimelineDay()
                        }
                    }
            )
        }
        .sheet(isPresented: $showingDayPicker) {
            dayPickerSheet
        }
    }

    private func pinnedDayNavigationHeader(
        for timeline: TimelineScreenState
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(timeline.weekTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

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
                    Text(timeline.selectedDayTitle)
                        .font(.title3.weight(.semibold))
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

                Button("Today") {
                    model.jumpTimelineToToday()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!timeline.showsJumpToToday)
                .accessibilityIdentifier("timeline-jump-to-today-button")

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

            HStack(spacing: 8) {
                ForEach(Array(timeline.pages.enumerated()), id: \.offset) { index, page in
                    Button {
                        model.showTimelineDay(page.date)
                    } label: {
                        VStack(spacing: 4) {
                            Text(page.shortWeekdayTitle)
                                .font(.caption.weight(.semibold))

                            Text(page.date.formatted(.dateTime.day()))
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(index == timeline.selectedPageIndex ? Color.white : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    index == timeline.selectedPageIndex ?
                                        Color.accentColor :
                                        Color(.secondarySystemGroupedBackground)
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("timeline-weekday-\(index)")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
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
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            .accessibilityIdentifier("timeline-sync-message")
    }

    private var timelinePageBinding: Binding<Int> {
        Binding(
            get: { profile.timeline.selectedPageIndex },
            set: { index in
                guard profile.timeline.pages.indices.contains(index) else {
                    return
                }

                model.showTimelineDay(profile.timeline.pages[index].date)
            }
        )
    }

    private var timelineDayBinding: Binding<Date> {
        Binding(
            get: { profile.timeline.selectedDay },
            set: { day in
                model.showTimelineDay(day)
            }
        )
    }
}
