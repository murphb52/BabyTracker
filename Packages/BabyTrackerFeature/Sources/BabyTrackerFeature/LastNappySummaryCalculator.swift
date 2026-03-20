import BabyTrackerDomain
import Foundation

public enum LastNappySummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent]
    ) -> LastNappySummaryViewState? {
        let nappyEvents = events.compactMap { event -> NappyEvent? in
            guard case let .nappy(nappyEvent) = event else {
                return nil
            }

            return nappyEvent
        }

        guard let lastNappy = nappyEvents.max(by: { left, right in
            left.metadata.occurredAt < right.metadata.occurredAt
        }) else {
            return nil
        }

        return LastNappySummaryViewState(
            title: BabyEventPresentation.title(for: .nappy),
            detailText: BabyEventPresentation.detailText(for: .nappy(lastNappy)),
            occurredAt: lastNappy.metadata.occurredAt
        )
    }
}
