import Foundation
import UIKit

@MainActor
final class CloudKitRemoteNotificationBridge {
    static let shared = CloudKitRemoteNotificationBridge()

    var handler: (() async -> UIBackgroundFetchResult)?

    private init() {}
}
