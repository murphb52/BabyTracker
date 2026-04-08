import Foundation

/// Hourly cumulative chart series for all four tracked categories in the Today tab.
public struct TodayChartData: Equatable, Sendable {
    /// Cumulative mL of bottle feed consumed per hour.
    public let bottle: HourlyCumulativeSeries

    /// Cumulative breast-feed session count per hour.
    public let breast: HourlyCumulativeSeries

    /// Cumulative minutes of completed sleep per hour.
    public let sleep: HourlyCumulativeSeries

    /// Cumulative nappy change count per hour.
    public let nappy: HourlyCumulativeSeries

    public init(
        bottle: HourlyCumulativeSeries,
        breast: HourlyCumulativeSeries,
        sleep: HourlyCumulativeSeries,
        nappy: HourlyCumulativeSeries
    ) {
        self.bottle = bottle
        self.breast = breast
        self.sleep = sleep
        self.nappy = nappy
    }
}
