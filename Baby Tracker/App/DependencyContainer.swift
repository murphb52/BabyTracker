import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation

struct DependencyKey<Value> {
    let name: String

    init(_ name: String) {
        self.name = name
    }
}

struct DependencyContainer {
    private var registrations: [String: Any] = [:]

    mutating func register<Value>(_ key: DependencyKey<Value>, value: Value) {
        registrations[key.name] = value
    }

    func resolve<Value>(_ key: DependencyKey<Value>) -> Value {
        guard let value = registrations[key.name] as? Value else {
            fatalError("Dependency not registered for key: \(key.name)")
        }

        return value
    }
}

extension DependencyKey {
    static let childRepository = DependencyKey<SwiftDataChildRepository>("childRepository")
    static let userIdentityRepository = DependencyKey<SwiftDataUserIdentityRepository>("userIdentityRepository")
    static let membershipRepository = DependencyKey<SwiftDataMembershipRepository>("membershipRepository")
    static let childSelectionStore = DependencyKey<UserDefaultsChildSelectionStore>("childSelectionStore")
    static let eventRepository = DependencyKey<SwiftDataEventRepository>("eventRepository")
    static let syncStateRepository = DependencyKey<SwiftDataSyncStateRepository>("syncStateRepository")
    static let recordMetadataRepository = DependencyKey<SwiftDataCloudKitRecordMetadataRepository>("recordMetadataRepository")
    static let liveActivityPreferenceStore = DependencyKey<UserDefaultsLiveActivityPreferenceStore>("liveActivityPreferenceStore")

    static let cloudKitClient = DependencyKey<any CloudKitClient>("cloudKitClient")
    static let liveActivityManager = DependencyKey<any FeedLiveActivityManaging>("liveActivityManager")
    static let localNotificationManager = DependencyKey<any LocalNotificationManaging>("localNotificationManager")
    static let hapticFeedbackProvider = DependencyKey<any HapticFeedbackProviding>("hapticFeedbackProvider")
}
