import CloudKit
import Foundation

enum CloudKitSubscriptionIDs {
    static func databaseSubscriptionID(for scope: CKDatabase.Scope) -> String {
        switch scope {
        case .private:
            return "com.adappt.BabyTracker.subscription.database.private"
        case .shared:
            return "com.adappt.BabyTracker.subscription.database.shared"
        case .public:
            return "com.adappt.BabyTracker.subscription.database.public"
        @unknown default:
            return "com.adappt.BabyTracker.subscription.database.unknown"
        }
    }
}
