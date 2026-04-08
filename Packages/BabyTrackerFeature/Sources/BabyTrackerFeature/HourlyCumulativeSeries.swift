import Foundation

/// A pair of cumulative hourly series: one for today, one for the 7-day average.
/// Used to power the overlay line chart in each Today-tab section card.
public struct HourlyCumulativeSeries: Equatable, Sendable {
    /// 24 values, index 0 = midnight, 23 = 11pm.
    /// Each value is the running total from midnight up to and including that hour.
    public let todayCumulative: [Int]

    /// 24 values, same layout. The 7-day average cumulative total per hour,
    /// computed over the 7 complete days before today and divided by 7.
    public let averageCumulative: [Int]

    public init(todayCumulative: [Int], averageCumulative: [Int]) {
        self.todayCumulative = todayCumulative
        self.averageCumulative = averageCumulative
    }

    /// A series with all zeros — used when there is no data.
    public static let zero = HourlyCumulativeSeries(
        todayCumulative: [Int](repeating: 0, count: 24),
        averageCumulative: [Int](repeating: 0, count: 24)
    )
}
