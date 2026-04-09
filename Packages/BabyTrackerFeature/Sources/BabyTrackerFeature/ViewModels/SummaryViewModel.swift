import BabyTrackerDomain
import Foundation
import Observation

/// Provides summary-screen data by observing the shared `AppModel`.
/// Views that access `events` automatically track changes to `appModel.events`
/// through Swift Observation's access-based dependency tracking.
@MainActor
@Observable
public final class SummaryViewModel {
    private let appModel: AppModel?
    private let fixedEvents: [BabyEvent]?
    private let fixedPreferredFeedVolumeUnit: FeedVolumeUnit?

    /// Production initialiser — events are sourced reactively from `appModel`.
    public init(appModel: AppModel) {
        self.appModel = appModel
        self.fixedEvents = nil
        self.fixedPreferredFeedVolumeUnit = nil
    }

    /// Preview / testing initialiser — events are provided directly.
    public init(
        events: [BabyEvent],
        preferredFeedVolumeUnit: FeedVolumeUnit = .milliliters
    ) {
        self.appModel = nil
        self.fixedEvents = events
        self.fixedPreferredFeedVolumeUnit = preferredFeedVolumeUnit
    }

    public var events: [BabyEvent] {
        appModel?.events ?? fixedEvents ?? []
    }

    public var preferredFeedVolumeUnit: FeedVolumeUnit {
        appModel?.currentChild?.preferredFeedVolumeUnit
            ?? fixedPreferredFeedVolumeUnit
            ?? .milliliters
    }

    public var emptyStateTitle: String { "No summary data yet" }
    public var emptyStateMessage: String { "Add events and your key trends will appear here." }
}
