import BabyTrackerDomain
import Foundation

public struct CurrentStatusCardViewState: Equatable, Sendable {
    public let visibleEventKinds: [BabyEventKind]
    public let rows: [CurrentStatusRowViewState]
    public let lastSleep: LastSleepSummaryViewState?

    public var timeSinceLastFeedAt: Date? {
        rows
            .filter { $0.kind == .breastFeed || $0.kind == .bottleFeed }
            .map(\.elapsedSinceDate)
            .max()
    }

    public var timeSinceLastNappyAt: Date? {
        row(for: .nappy)?.elapsedSinceDate
    }

    public init(
        visibleEventKinds: [BabyEventKind],
        rows: [CurrentStatusRowViewState],
        lastSleep: LastSleepSummaryViewState?
    ) {
        self.visibleEventKinds = visibleEventKinds
        self.rows = rows
        self.lastSleep = lastSleep
    }

    public func row(for kind: BabyEventKind) -> CurrentStatusRowViewState? {
        rows.first { $0.kind == kind }
    }
}
