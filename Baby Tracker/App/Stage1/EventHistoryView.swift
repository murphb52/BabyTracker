import BabyTrackerFeature
import SwiftUI

struct EventHistoryView: View {
    let profile: ChildProfileScreenState
    let openEvent: (EventCardViewState) -> Void
    let deleteEvent: (EventCardViewState) -> Void

    var body: some View {
        List {
            if profile.eventHistory.events.isEmpty {
                emptyState
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(profile.eventHistory.events) { event in
                    eventRow(for: event)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func eventRow(for event: EventCardViewState) -> some View {
        if profile.canManageEvents {
            Button {
                openEvent(event)
            } label: {
                EventCardView(event: event)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("event-history-event-\(event.id.uuidString)")
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button(primaryActionTitle(for: event)) {
                    openEvent(event)
                }
            }
            .swipeActions {
                Button("Delete", role: .destructive) {
                    deleteEvent(event)
                }
            }
        } else {
            EventCardView(event: event)
                .accessibilityIdentifier("event-history-event-\(event.id.uuidString)")
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(profile.eventHistory.emptyStateTitle)
                .font(.headline)
            Text(profile.eventHistory.emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityIdentifier("event-history-empty-state")
    }

    private func primaryActionTitle(for event: EventCardViewState) -> String {
        switch event.actionPayload {
        case .endSleep:
            "End"
        case .editBreastFeed, .editBottleFeed, .editNappy, .editSleep:
            "Edit"
        }
    }
}
