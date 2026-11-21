import BabyTrackerDomain
import Foundation

/// Runs the domain queries for one child and phrases the results for the model.
///
/// It is a `@MainActor` class because the repositories are main-actor bound.
/// That also makes it `Sendable`, which the Foundation Models `Tool`
/// protocol requires of anything a tool holds.
@MainActor
final class AssistantDataSource {
    private let childID: UUID
    private let calendar: Calendar
    private let now: () -> Date
    private let fetchLastEvent: FetchLastEventUseCase
    private let summarizeEvents: SummarizeEventsInRangeUseCase
    private let findDailyPattern: FindDailyPatternUseCase

    init(
        childID: UUID,
        eventRepository: any EventRepository,
        calendar: Calendar,
        now: @escaping () -> Date
    ) {
        self.childID = childID
        self.calendar = calendar
        self.now = now
        self.fetchLastEvent = FetchLastEventUseCase(eventRepository: eventRepository)
        self.summarizeEvents = SummarizeEventsInRangeUseCase(eventRepository: eventRepository, calendar: calendar)
        self.findDailyPattern = FindDailyPatternUseCase(eventRepository: eventRepository, calendar: calendar)
    }

    func lastEventText(category: EventSummaryCategory) throws -> String {
        let event = try fetchLastEvent.execute(.init(childID: childID, category: category))
        return AssistantToolText.lastEvent(event, category: category, now: now(), calendar: calendar)
    }

    func summaryText(category: EventSummaryCategory, period: RelativePeriod) throws -> String {
        AssistantToolText.summary(try summary(category: category, period: period))
    }

    func comparisonText(
        category: EventSummaryCategory,
        currentPeriod: RelativePeriod,
        earlierPeriod: RelativePeriod
    ) throws -> String {
        AssistantToolText.comparison(
            current: try summary(category: category, period: currentPeriod),
            earlier: try summary(category: category, period: earlierPeriod)
        )
    }

    func patternText(category: EventSummaryCategory, period: RelativePeriod) throws -> String {
        let pattern = try findDailyPattern.execute(
            .init(childID: childID, category: category, period: period, now: now())
        )
        return AssistantToolText.pattern(pattern)
    }

    private func summary(category: EventSummaryCategory, period: RelativePeriod) throws -> EventRangeSummary {
        try summarizeEvents.execute(
            .init(childID: childID, category: category, period: period, now: now())
        )
    }
}
