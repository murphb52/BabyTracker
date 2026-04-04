import BabyTrackerDomain
import Foundation
import Observation

/// Owns the event history filter state and provides the filtered event list,
/// computed directly from `AppModel` raw data.
@MainActor
@Observable
public final class EventHistoryViewModel {
    private let appModel: AppModel
    private let calendar = Calendar.current

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var events: [EventCardViewState] {
        sections.flatMap(\.events)
    }

    public var sections: [EventHistorySectionViewState] {
        guard let child = appModel.currentChild else { return [] }
        let filter = appModel.activeEventFilter
        let filtered = filter.isEmpty
            ? appModel.events
            : appModel.events.filter { filter.matches($0) }

        let grouped = Dictionary(grouping: filtered) { event in
            calendar.startOfDay(for: event.metadata.occurredAt)
        }

        return grouped
            .map { day, events in
                EventHistorySectionViewState(
                    date: day,
                    events: BuildEventCardsUseCase.execute(
                        events: events,
                        preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                    )
                )
            }
            .sorted { $0.date > $1.date }
    }

    public var activeFilter: EventFilter {
        appModel.activeEventFilter
    }

    public var filterIsActive: Bool {
        !appModel.activeEventFilter.isEmpty
    }

    public var emptyStateTitle: String {
        appModel.activeEventFilter.isEmpty ? "No events logged yet" : "No matching events"
    }

    public var emptyStateMessage: String {
        appModel.activeEventFilter.isEmpty
            ? "Use Quick Log on Home to add the first event."
            : "Try adjusting or clearing your filters."
    }

    // MARK: - Actions

    public func updateFilter(_ filter: EventFilter) {
        appModel.updateEventFilter(filter)
    }
}

public struct EventHistorySectionViewState: Identifiable, Equatable, Sendable {
    public let date: Date
    public let events: [EventCardViewState]

    public var id: Date { date }

    public init(date: Date, events: [EventCardViewState]) {
        self.date = date
        self.events = events
    }
}
