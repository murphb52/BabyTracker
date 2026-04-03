import SwiftUI

public struct TimelineDayPageView: View {
    let page: TimelineDayPageState
    let canManageEvents: Bool
    let openEvent: (TimelineEventBlockViewState) -> Void
    let deleteEvent: (TimelineEventBlockViewState) -> Void
    let pendingDeleteEvent: EventDeleteCandidate?
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

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
        VStack {
            Text("Day grid coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("timeline-day-placeholder")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

#Preview {
    TimelineDayPageView(
        page: TimelineDayPageState(
            date: .now,
            dayTitle: "Today",
            shortWeekdayTitle: "Fri",
            isToday: true,
            blocks: [],
            emptyStateTitle: "No events for this day",
            emptyStateMessage: "Try another day or use Quick Log to add the next event."
        ),
        canManageEvents: true,
        openEvent: { _ in },
        deleteEvent: { _ in },
        pendingDeleteEvent: nil,
        confirmDelete: {},
        cancelDelete: {}
    )
}
