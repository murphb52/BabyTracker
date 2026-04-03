import BabyTrackerDomain
import Foundation

/// Transforms a collection of domain events into `EventCardViewState` values
/// ready for display in list-style views such as the event history screen.
public enum BuildEventCardsUseCase {
    public static func execute(
        events: [BabyEvent],
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) -> [EventCardViewState] {
        events.compactMap {
            EventCardViewState(event: $0, preferredFeedVolumeUnit: preferredFeedVolumeUnit)
        }
    }
}
