import BabyTrackerDomain
import Foundation

public enum LastEventSummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent]
    ) -> LastEventSummaryViewState? {
        guard let lastEvent = FindLatestEventUseCases.latestEvent(from: events) else {
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
