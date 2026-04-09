import BabyTrackerDomain
import StoreKit
import UIKit

final class SystemAppReviewRequester: AppReviewRequesting {
    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }
}
