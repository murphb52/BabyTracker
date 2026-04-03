import BabyTrackerDomain
import Foundation
import Observation

/// Owns the event history filter state and provides the filtered event list,
/// computed directly from `AppModel` raw data.
@MainActor
@Observable
public final class EventHistoryViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var events: [EventCardViewState] {
        guard let child = appModel.currentChild else { return [] }
        let filter = appModel.activeEventFilter
        let filtered = filter.isEmpty
            ? appModel.events
            : appModel.events.filter { filter.matches($0) }
        return BuildEventCardsUseCase.execute(
            events: filtered,
            preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
        )
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
