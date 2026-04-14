import BabyTrackerDomain
import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation

public struct FirebaseAnalyticsTracker: AnalyticsTracking {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
}

public struct FirebaseCrashReporter: Sendable {
    public init() {}

    public func record(_ error: any Error) {
        Crashlytics.crashlytics().record(error: error)
    }
}

