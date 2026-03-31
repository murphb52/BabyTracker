import BabyTrackerDomain
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation

enum ChildProfilePreviewFactory {
    @MainActor
    static func makeModel() -> AppModel {
        let suiteName = "ChildProfilePreview"
        let userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = try! BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let recordMetadataRepository = SwiftDataCloudKitRecordMetadataRepository(store: store)
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            recordMetadataRepository: recordMetadataRepository,
            client: UnavailableCloudKitClient()
        )
        let model = AppModel(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            syncEngine: syncEngine,
            liveActivityManager: NoOpFeedLiveActivityManager(),
            liveActivityPreferenceStore: InMemoryLiveActivityPreferenceStore(),
            localNotificationManager: NoOpLocalNotificationManager(),
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )

        model.load(performLaunchSync: false)
        model.createLocalUser(displayName: "Alex Parent")
        model.createChild(name: "Poppy", birthDate: Date())
        return model
    }
}
