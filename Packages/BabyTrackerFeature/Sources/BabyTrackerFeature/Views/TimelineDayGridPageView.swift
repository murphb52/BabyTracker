import SwiftUI

public struct TimelineDayGridPageView: View {
    let page: TimelineDayGridPageState
    let canManageEvents: Bool
    let openItem: (TimelineDayGridItemViewState) -> Void
    let deleteItem: (TimelineDayGridItemViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    public init(
        page: TimelineDayGridPageState,
        canManageEvents: Bool,
        openItem: @escaping (TimelineDayGridItemViewState) -> Void,
        deleteItem: @escaping (TimelineDayGridItemViewState) -> Void,
        pendingDeleteEvent: EventDeleteCandidate?,
        confirmDelete: @escaping () -> Void,
        cancelDelete: @escaping () -> Void
    ) {
        self.page = page
        self.canManageEvents = canManageEvents
        self.openItem = openItem
        self.deleteItem = deleteItem
        self.pendingDeleteEvent = pendingDeleteEvent
        self.confirmDelete = confirmDelete
        self.cancelDelete = cancelDelete
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if page.grid == nil {
                        emptyState(
                            title: page.emptyStateTitle,
                            message: page.emptyStateMessage
                        )
                    }

                    if let grid = page.grid {
                        TimelineDayGridView(
                            day: page.date,
                            grid: grid,
                            canManageEvents: canManageEvents,
                            openItem: openItem,
                            deleteItem: deleteItem,
                            pendingDeleteEvent: pendingDeleteEvent,
                            confirmDelete: confirmDelete,
                            cancelDelete: cancelDelete
                        )
                    }
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

    private func scrollToVisibleHour(using proxy: ScrollViewProxy) {
        let calendar = Calendar.autoupdatingCurrent
        let visibleHour = page.isToday ? calendar.component(.hour, from: .now) : 6

        DispatchQueue.main.async {
            proxy.scrollTo("timeline-day-grid-hour-\(visibleHour)", anchor: .top)
        }
    }
}

#Preview("Empty") {
    TimelineDayGridPageView(
        page: TimelineDayGridPageState(
            date: .now,
            dayTitle: "Today",
            shortWeekdayTitle: "Fri",
            isToday: true,
            grid: nil,
            emptyStateTitle: "No events for this day",
            emptyStateMessage: "Try another day or use Quick Log to add the next event."
        ),
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
}

#Preview("With Grid") {
    TimelineDayGridPageView(
        page: TimelineDayGridPageState(
            date: .now,
            dayTitle: "Today",
            shortWeekdayTitle: "Fri",
            isToday: true,
            grid: TimelineDayGridViewState(
                slotMinutes: 15,
                columns: [
                    TimelineDayGridColumnViewState(
                        kind: .sleep,
                        title: "Sleep",
                        items: [
                            TimelineDayGridItemViewState(
                                id: "sleep-1",
                                columnKind: .sleep,
                                startSlotIndex: 8,
                                endSlotIndex: 20,
                                eventIDs: [UUID()],
                                count: 1,
                                title: "3h",
                                detailText: "02:00",
                                timeText: "05:00",
                                actionPayloads: [
                                    EventActionPayload.editSleep(startedAt: .now, endedAt: .now)
                                ]
                            )
                        ]
                    ),
                    TimelineDayGridColumnViewState(
                        kind: .nappy,
                        title: "Nappy",
                        items: [
                            TimelineDayGridItemViewState(
                                id: "nappy-1",
                                columnKind: .nappy,
                                startSlotIndex: 24,
                                endSlotIndex: 25,
                                eventIDs: [UUID()],
                                count: 1,
                                title: "Pee",
                                detailText: "",
                                timeText: "",
                                actionPayloads: [
                                    EventActionPayload.editNappy(type: .wee, occurredAt: .now, peeVolume: nil, pooVolume: nil, pooColor: nil)
                                ]
                            )
                        ]
                    ),
                    TimelineDayGridColumnViewState(
                        kind: .bottleFeed,
                        title: "Bottle",
                        items: []
                    ),
                    TimelineDayGridColumnViewState(
                        kind: .breastFeed,
                        title: "Breast",
                        items: [
                            TimelineDayGridItemViewState(
                                id: "breast-1",
                                columnKind: .breastFeed,
                                startSlotIndex: 32,
                                endSlotIndex: 36,
                                eventIDs: [UUID(), UUID()],
                                count: 2,
                                title: "2 events",
                                detailText: "Multiple events",
                                timeText: "08:00-09:00",
                                actionPayloads: [
                                    EventActionPayload.editBreastFeed(durationMinutes: 15, endTime: .now, side: nil, leftDurationSeconds: nil, rightDurationSeconds: nil),
                                    EventActionPayload.editBreastFeed(durationMinutes: 20, endTime: .now, side: .left, leftDurationSeconds: nil, rightDurationSeconds: nil)
                                ]
                            )
                        ]
                    )
                ]
            ),
            emptyStateTitle: "No events for this day",
            emptyStateMessage: "Try another day or use Quick Log to add the next event."
        ),
        canManageEvents: true,
        openItem: { _ in },
        deleteItem: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
}
