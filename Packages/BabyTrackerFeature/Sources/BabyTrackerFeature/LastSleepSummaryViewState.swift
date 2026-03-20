import Foundation

public struct LastSleepSummaryViewState: Equatable, Sendable {
    public let isActive: Bool
    public let startedAt: Date
    public let endedAt: Date?

    public init(
        isActive: Bool,
        startedAt: Date,
        endedAt: Date?
    ) {
        self.isActive = isActive
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}
