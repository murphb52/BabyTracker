import BabyTrackerDomain
import Foundation

/// Produces the current-status card state for the home screen by composing
/// generic per-kind latest-event rows plus the explicit active-sleep exception.
public enum BuildCurrentStatusViewStateUseCase {
    public static func execute(
        events: [BabyEvent],
        child: Child,
        enabledEventKinds: Set<BabyEventKind>,
        activeSleep: SleepEvent? = nil,
        day: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> CurrentStatusCardViewState {
        let _ = day
        let _ = calendar

        let visibleEventKinds = BabyEventKind.allCases.filter(enabledEventKinds.contains)
        let lastSleep = LastSleepSummaryCalculator.makeSummary(from: events, activeSleep: activeSleep)

        let rows = visibleEventKinds.compactMap { kind -> CurrentStatusRowViewState? in
            switch kind {
            case .sleep:
                return completedSleepRow(from: lastSleep)
            case .bath, .breastFeed, .bottleFeed, .nappy, .medication:
                return latestEventRow(
                    for: kind,
                    events: events,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                )
            }
        }

        return CurrentStatusCardViewState(
            visibleEventKinds: visibleEventKinds,
            rows: rows,
            lastSleep: lastSleep
        )
    }

    private static func latestEventRow(
        for kind: BabyEventKind,
        events: [BabyEvent],
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) -> CurrentStatusRowViewState? {
        guard let lastEvent = events
            .filter({ $0.kind == kind })
            .max(by: { $0.metadata.occurredAt < $1.metadata.occurredAt }) else {
            return nil
        }

        return CurrentStatusRowViewState(
            kind: kind,
            title: rowTitle(for: kind),
            detailText: BabyEventPresentation.detailText(
                for: lastEvent,
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ),
            elapsedSinceDate: lastEvent.metadata.occurredAt,
            emptyValueText: emptyValueText(for: kind)
        )
    }

    private static func completedSleepRow(
        from summary: LastSleepSummaryViewState?
    ) -> CurrentStatusRowViewState? {
        guard let summary,
              summary.isActive == false,
              let endedAt = summary.endedAt else {
            return nil
        }

        let minutes = max(1, Int(endedAt.timeIntervalSince(summary.startedAt) / 60))

        return CurrentStatusRowViewState(
            kind: .sleep,
            title: rowTitle(for: .sleep),
            detailText: DurationText.short(minutes: minutes, minuteStyle: .word),
            elapsedSinceDate: endedAt,
            emptyValueText: emptyValueText(for: .sleep)
        )
    }

    static func rowTitle(for kind: BabyEventKind) -> String {
        "Last \(BabyEventPresentation.title(for: kind).lowercased())"
    }

    static func emptyValueText(for kind: BabyEventKind) -> String {
        switch kind {
        case .bath:
            "No baths yet"
        case .breastFeed, .bottleFeed:
            "No feeds yet"
        case .sleep:
            "No sleep yet"
        case .nappy:
            "No nappies yet"
        case .medication:
            "No medications yet"
        }
    }
}
