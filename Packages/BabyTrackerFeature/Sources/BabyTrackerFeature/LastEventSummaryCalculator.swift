import BabyTrackerDomain
import Foundation

public enum LastEventSummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent]
    ) -> LastEventSummaryViewState? {
        guard let lastEvent = events.max(by: { left, right in
            left.metadata.occurredAt < right.metadata.occurredAt
        }) else {
            return nil
        }

        return LastEventSummaryViewState(
            kind: lastEvent.kind,
            title: BabyEventPresentation.title(for: lastEvent),
            detailText: BabyEventPresentation.detailText(for: lastEvent),
            occurredAt: lastEvent.metadata.occurredAt
        )
    }
}
