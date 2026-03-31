import Foundation

public enum AdvancedSummarySelectionMode: String, CaseIterable, Identifiable, Sendable {
    case range
    case day

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .range:
            "Range"
        case .day:
            "Day"
        }
    }
}

public struct AdvancedSummarySelection: Equatable, Sendable {
    public var mode: AdvancedSummarySelectionMode
    public var range: SummaryTimeRange
    public var day: Date

    public init(
        mode: AdvancedSummarySelectionMode,
        range: SummaryTimeRange,
        day: Date
    ) {
        self.mode = mode
        self.range = range
        self.day = day
    }

    public static func range(_ range: SummaryTimeRange, day: Date = .now) -> AdvancedSummarySelection {
        AdvancedSummarySelection(mode: .range, range: range, day: day)
    }
}
