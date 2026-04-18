import SwiftUI

public struct TimelineScreenView: View {
    private let defaultDayPickerSheetHeight: CGFloat = 420

    let viewModel: TimelineViewModel
    let openEvent: (TimelineDayGridItemViewState) -> Void
    let deleteEvent: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    @State private var showingDayPicker = false
    @State private var dragStartPageIndex: Int = 0
    @State private var dayPickerSheetHeight: CGFloat = 420

    public init(
        viewModel: TimelineViewModel,
        openEvent: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteEvent: @escaping (TimelineDayGridItemViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.openEvent = openEvent
        self.deleteEvent = deleteEvent
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        Group {
            if viewModel.displayMode == .day {
                dayPagerContent
            } else {
                TimelineWeekView(
                    columns: viewModel.stripColumns,
                    selectedDay: viewModel.selectedDay,
                    showDay: viewModel.showDay
                )
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
        }
        .navigationTitle(viewModel.selectedDayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.showPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityIdentifier("timeline-previous-day-button")
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(viewModel.displayMode == .day ? "Week" : "Day") {
                    viewModel.toggleDisplayMode()
                }
                .accessibilityIdentifier("timeline-display-mode-button")

                Button {
                    showingDayPicker = true
                } label: {
                    Image(systemName: "calendar")
                }
                .accessibilityIdentifier("timeline-day-picker-button")

                Button("Today") {
                    viewModel.jumpToToday()
                }
                .disabled(!viewModel.showsJumpToToday)
                .accessibilityIdentifier("timeline-jump-to-today-button")

                Button {
                    viewModel.showNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canMoveToNextDay)
                .accessibilityIdentifier("timeline-next-day-button")
            }
        }
        // The weekday strip and optional sync banner live in a safeAreaBar so they
        // participate in the safe area layout instead of floating over content.
        .safeAreaBar(edge: .top) {
            VStack(spacing: 0) {
                if viewModel.displayMode == .day {
                    weekdayStrip
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }

                if let syncMessage = viewModel.syncMessage {
                    syncBanner(message: syncMessage)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .background(.regularMaterial)
        }
        .sheet(isPresented: $showingDayPicker) {
            dayPickerSheet
        }
        .confirmationDialog(
            pendingDeleteEvent?.dialogTitle ?? "Delete Event?",
            isPresented: timelineDeleteDialogBinding,
            presenting: pendingDeleteEvent
        ) { event in
            Button(event.confirmButtonTitle, role: .destructive) {
                confirmDelete()
            }

            Button("Cancel", role: .cancel) {
                cancelDelete()
            }
        } message: { event in
            if !event.timestampText.isEmpty {
                Text(event.timestampText)
            }
        }
    }

    private var dayPagerContent: some View {
        TabView(selection: timelinePageBinding) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                TimelineDayGridPageView(
                    page: page,
                    canManageEvents: viewModel.canManageEvents,
                    openItem: openEvent,
                    deleteItem: deleteEvent
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { _ in
                    if dragStartPageIndex != viewModel.selectedPageIndex {
                        dragStartPageIndex = viewModel.selectedPageIndex
                    }
                }
                .onEnded { value in
                    let swipe = value.translation.width
                    if swipe > 60 && dragStartPageIndex == 0 {
                        viewModel.showPreviousDay()
                    } else if swipe < -60 && dragStartPageIndex == viewModel.pages.count - 1 {
                        viewModel.showNextDay()
                    }
                }
        )
    }

    private var weekdayStrip: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                Button {
                    viewModel.showDay(page.date)
                } label: {
                    VStack(spacing: 4) {
                        Text(page.shortWeekdayTitle)
                            .font(.caption.weight(.semibold))

                        Text(page.date.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(index == viewModel.selectedPageIndex ? Color.accentColor : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timeline-weekday-\(index)")
            }
        }
    }

    private var dayPickerSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            dayPickerSheetHeader

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
        .fixedSize(horizontal: false, vertical: true)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .task(id: geometry.size.height) {
                        dayPickerSheetHeight = max(defaultDayPickerSheetHeight, geometry.size.height)
                    }
            }
        }
        .presentationDetents([.height(dayPickerSheetHeight)])
        .presentationDragIndicator(.visible)
    }

    private var dayPickerSheetHeader: some View {
        HStack {
            Button("Today") {
                viewModel.jumpToToday()
                showingDayPicker = false
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("timeline-day-picker-today-button")

            Spacer()

            Button("Done") {
                showingDayPicker = false
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("timeline-day-picker-done-button")
        }
        .overlay {
            Text("Choose Day")
                .font(.headline.weight(.semibold))
        }
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
            get: { viewModel.selectedPageIndex },
            set: { index in
                guard viewModel.pages.indices.contains(index) else {
                    return
                }

                viewModel.showDay(viewModel.pages[index].date)
            }
        )
    }

    private var timelineDayBinding: Binding<Date> {
        Binding(
            get: { viewModel.selectedDay },
            set: { day in
                viewModel.showDay(day)
            }
        )
    }

    private var timelineDeleteDialogBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteEvent != nil && viewModel.displayMode == .day },
            set: { isPresented in
                if !isPresented {
                    cancelDelete()
                }
            }
        )
    }
}

#Preview {
    NavigationStack {
        let model = ChildProfilePreviewFactory.makeModel()
        TimelineScreenView(
            viewModel: TimelineViewModel(appModel: model),
            openEvent: { _ in },
            deleteEvent: { _ in },
            pendingDeleteEvent: nil,
            confirmDelete: {},
            cancelDelete: {}
        )
    }
}
