import BabyTrackerDomain
import Foundation

final class UserDefaultsAppReviewPromptStateStore: AppReviewPromptStateStoring {
    private enum Keys {
        static let loggedEventCount = "app_review.logged_event_count"
        static let hasRequestedReview = "app_review.has_requested_review"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    var loggedEventCount: Int {
        get {
            userDefaults.integer(forKey: Keys.loggedEventCount)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.loggedEventCount)
        }
    }

    var hasRequestedReview: Bool {
        get {
            userDefaults.bool(forKey: Keys.hasRequestedReview)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.hasRequestedReview)
        }
    }
}
