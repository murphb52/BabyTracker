import BabyTrackerDomain
import Foundation
import Observation

/// Owns the event history filter state and provides the filtered event list.
///
/// During the staged migration, filter changes are forwarded to `AppModel` which
/// rebuilds `profile.eventHistory` using the updated filter. The computed
/// properties simply mirror `profile.eventHistory.*` so views bind to this
/// ViewModel rather than to `profile.eventHistory` directly.
///
/// When `ChildProfileScreenState` is removed, this ViewModel will hold raw
/// events and apply the filter itself without delegating to AppModel.
@MainActor
@Observable
public final class EventHistoryViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state (bridge to profile.eventHistory)

    public var events: [EventCardViewState] {
        appModel.profile?.eventHistory.events ?? []
    }

    public var activeFilter: EventFilter {
        appModel.profile?.eventHistory.activeFilter ?? .empty
    }

    public var filterIsActive: Bool {
        appModel.profile?.eventHistory.filterIsActive ?? false
    }

    public var emptyStateTitle: String {
        appModel.profile?.eventHistory.emptyStateTitle ?? "No events logged yet"
    }

    public var emptyStateMessage: String {
        appModel.profile?.eventHistory.emptyStateMessage
            ?? "Use Quick Log on Home to add the first event."
    }

    // MARK: - Actions

    public func updateFilter(_ filter: EventFilter) {
        appModel.updateEventFilter(filter)
    }
}
