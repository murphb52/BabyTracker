import SwiftUI
import UIKit

public struct TimelineScreenView: View {
    private let defaultDayPickerSheetHeight: CGFloat = 420

    let viewModel: TimelineViewModel
    let openEvent: (TimelineDayGridItemViewState) -> Void
    let deleteEvent: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    @State private var showingDayPicker = false
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
        VStack(spacing: 0) {
            pinnedDayNavigationHeader

            if let syncMessage = viewModel.syncMessage {
                syncBanner(message: syncMessage)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            if viewModel.displayMode == .day {
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
            } else {
                TimelineWeekView(
                    columns: viewModel.stripColumns,
                    selectedDay: viewModel.selectedDay,
                    showDay: viewModel.showDay
                )
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
            }
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

    private var pinnedDayNavigationHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.weekTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    viewModel.showPreviousDay()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("timeline-previous-day-button")

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedDayTitle)
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
                    viewModel.jumpToToday()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.showsJumpToToday)
                .accessibilityIdentifier("timeline-jump-to-today-button")

                Button {
                    viewModel.showNextDay()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canMoveToNextDay)
                .accessibilityIdentifier("timeline-next-day-button")
            }

            if viewModel.displayMode == .day {
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
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(headerBackgroundStyle)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(isIncreaseContrastEnabled ? Color.primary.opacity(0.45) : Color.clear)
        }
    }

    private var headerBackgroundStyle: AnyShapeStyle {
        isReduceTransparencyEnabled
            ? AnyShapeStyle(Color(.secondarySystemGroupedBackground))
            : AnyShapeStyle(.regularMaterial)
    }

    private var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    private var isIncreaseContrastEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
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
