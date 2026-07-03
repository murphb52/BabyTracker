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

    // Caches below are keyed on the exact inputs that produced them. Each of
    // the calculators they front does multiple O(n) passes over the full
    // event history, so re-running them on every SwiftUI body evaluation
    // (including ones triggered by unrelated `AppModel` state) is wasteful.
    // These are `@ObservationIgnored` so writing to them from a computed
    // property getter doesn't itself register as an observed mutation.
    @ObservationIgnored private var cachedTodaySummary: (events: [BabyEvent], day: Date, value: TodaySummaryData)?
    @ObservationIgnored private var cachedTrendsSummary: (events: [BabyEvent], range: TrendsTimeRange, value: TrendsSummaryData)?
    @ObservationIgnored private var cachedAdvancedSummary: (events: [BabyEvent], selection: AdvancedSummarySelection, value: AdvancedSummaryViewState)?

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

    public var enabledEventKinds: Set<BabyEventKind> {
        appModel?.enabledEventKinds ?? Set(BabyEventKind.allCases)
    }

    public var emptyStateTitle: String { "No summary data yet" }
    public var emptyStateMessage: String { "Add events and your key trends will appear here." }

    public func todaySummaryData(for day: Date) -> TodaySummaryData {
        let currentEvents = events
        if let cached = cachedTodaySummary, cached.day == day, cached.events == currentEvents {
            return cached.value
        }
        let value = TodaySummaryCalculator.makeData(from: currentEvents, day: day)
        cachedTodaySummary = (currentEvents, day, value)
        return value
    }

    public func trendsSummaryData(for range: TrendsTimeRange) -> TrendsSummaryData {
        let currentEvents = events
        if let cached = cachedTrendsSummary, cached.range == range, cached.events == currentEvents {
            return cached.value
        }
        let value = TrendsSummaryCalculator.makeData(from: currentEvents, range: range)
        cachedTrendsSummary = (currentEvents, range, value)
        return value
    }

    public func advancedSummaryViewState(for selection: AdvancedSummarySelection) -> AdvancedSummaryViewState {
        let currentEvents = events
        if let cached = cachedAdvancedSummary, cached.selection == selection, cached.events == currentEvents {
            return cached.value
        }
        let value = AdvancedSummaryMetricsCalculator.makeViewState(from: currentEvents, selection: selection)
        cachedAdvancedSummary = (currentEvents, selection, value)
        return value
    }
}
