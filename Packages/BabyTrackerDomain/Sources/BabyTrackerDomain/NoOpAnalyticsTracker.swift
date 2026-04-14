public struct NoOpAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(_ event: AnalyticsEvent) {}
}

