import BabyTrackerDomain
import Foundation

public enum LastNappySummaryCalculator {
    public static func makeSummary(
        from events: [BabyEvent]
    ) -> LastNappySummaryViewState? {
        guard let lastNappy = FindLatestEventUseCases.latestNappy(from: events) else {
            return nil
        }

        return LastNappySummaryViewState(
            title: BabyEventPresentation.title(for: .nappy),
            detailText: BabyEventPresentation.detailText(for: .nappy(lastNappy)),
            occurredAt: lastNappy.metadata.occurredAt
        )
    }
}
