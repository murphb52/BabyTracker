import Foundation

/// Controls whether the timeline shows a single-day paged view or the weekly
/// strip overview.
public enum TimelineDisplayMode: Equatable, Sendable {
    case day
    case week
}
