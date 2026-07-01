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

    // `sections` does a sort/filter/group-by-day pass plus per-event card
    // building over the full event history. Cache it, keyed on the exact
    // inputs that produced it, so unrelated `AppModel` mutations (or repeat
    // SwiftUI body evaluations) don't force a full recompute.
    @ObservationIgnored private var cachedSections: (
        events: [BabyEvent],
        filter: EventFilter,
        preferredFeedVolumeUnit: FeedVolumeUnit,
        value: [EventHistorySectionViewState]
    )?

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var events: [EventCardViewState] {
        sections.flatMap(\.events)
    }

    public var sections: [EventHistorySectionViewState] {
        guard let child = appModel.currentChild else { return [] }
        let currentEvents = appModel.events
        let filter = appModel.activeEventFilter
        let preferredFeedVolumeUnit = child.preferredFeedVolumeUnit

        if let cached = cachedSections,
           cached.filter == filter,
           cached.preferredFeedVolumeUnit == preferredFeedVolumeUnit,
           cached.events == currentEvents {
            return cached.value
        }

        let filtered = filter.isEmpty
            ? currentEvents
            : currentEvents.filter { filter.matches($0) }

        let grouped = Dictionary(grouping: filtered) { event in
            calendar.startOfDay(for: event.metadata.occurredAt)
        }

        let value = grouped
            .map { day, events in
                EventHistorySectionViewState(
                    date: day,
                    events: BuildEventCardsUseCase.execute(
                        events: events,
                        preferredFeedVolumeUnit: preferredFeedVolumeUnit
                    )
                )
            }
            .sorted { $0.date > $1.date }

        cachedSections = (currentEvents, filter, preferredFeedVolumeUnit, value)
        return value
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
