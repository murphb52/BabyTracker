import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import BabyTrackerSync
import Foundation

@MainActor
struct AppContainer {
    let appModel: AppModel
    let shareAcceptanceHandler: ShareAcceptanceHandler

    init(processInfo: ProcessInfo = .processInfo) {
        let launchConfiguration = LaunchConfiguration(processInfo: processInfo)
        let userDefaults = launchConfiguration.makeUserDefaults()
        let store = try! BabyTrackerModelStore(
            isStoredInMemoryOnly: launchConfiguration.usesInMemoryStore
        )
        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let recordMetadataRepository = SwiftDataCloudKitRecordMetadataRepository(store: store)
        let liveActivityPreferenceStore = UserDefaultsLiveActivityPreferenceStore(userDefaults: userDefaults)

        if let scenario = launchConfiguration.scenario {
            try? Self.seed(
                scenario: scenario,
                childRepository: childRepository,
                userIdentityRepository: userIdentityRepository,
                membershipRepository: membershipRepository,
                childSelectionStore: childSelectionStore,
                eventRepository: eventRepository
            )
        }

        let cloudKitClient: any CloudKitClient = launchConfiguration.usesUnavailableCloudKitClient ?
            UnavailableCloudKitClient() :
            LiveCloudKitClient()
        let liveActivityManager: any FeedLiveActivityManaging = launchConfiguration.usesNoOpLiveActivities ?
            NoOpFeedLiveActivityManager() :
            FeedLiveActivityManager()
        let localNotificationManager: any LocalNotificationManaging = launchConfiguration.usesUnavailableCloudKitClient ?
            NoOpLocalNotificationManager() :
            SystemLocalNotificationManager()
        let hapticFeedbackProvider: any HapticFeedbackProviding = SystemHapticFeedbackProvider()
        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            recordMetadataRepository: recordMetadataRepository,
            client: cloudKitClient
        )
        let appModel = AppModel(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            syncEngine: syncEngine,
            liveActivityManager: liveActivityManager,
            liveActivityPreferenceStore: liveActivityPreferenceStore,
            localNotificationManager: localNotificationManager,
            hapticFeedbackProvider: hapticFeedbackProvider
        )
        let shareAcceptanceHandler = ShareAcceptanceHandler(
            syncEngine: syncEngine,
            onStartAcceptingShare: {
                appModel.beginAcceptingSharedChild()
            },
            onAcceptedShare: {
                appModel.completeAcceptingSharedChild()
            },
            onFailedToAcceptShare: { error in
                appModel.failAcceptingSharedChild(error)
            }
        )
        appModel.load(performLaunchSync: !launchConfiguration.skipsLaunchSync)

        self.appModel = appModel
        self.shareAcceptanceHandler = shareAcceptanceHandler
    }

    static let live = AppContainer()

    static let preview: AppContainer = {
        let processInfo = ProcessInfo.processInfo
        let launchConfiguration = LaunchConfiguration(
            usesInMemoryStore: true,
            userDefaultsSuiteName: "BabyTrackerPreview",
            scenario: .mixedEventsPreview
        )
        let userDefaults = launchConfiguration.makeUserDefaults()
        let store = try! BabyTrackerModelStore(isStoredInMemoryOnly: true)
        let childRepository = SwiftDataChildRepository(store: store)
        let userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
        let membershipRepository = SwiftDataMembershipRepository(store: store)
        let childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
        let eventRepository = SwiftDataEventRepository(store: store)
        let syncStateRepository = SwiftDataSyncStateRepository(store: store)
        let recordMetadataRepository = SwiftDataCloudKitRecordMetadataRepository(store: store)
        let liveActivityPreferenceStore = UserDefaultsLiveActivityPreferenceStore(userDefaults: userDefaults)

        try? seed(
            scenario: .mixedEventsPreview,
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository
        )

        let syncEngine = CloudKitSyncEngine(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            eventRepository: eventRepository,
            syncStateRepository: syncStateRepository,
            recordMetadataRepository: recordMetadataRepository,
            client: UnavailableCloudKitClient()
        )
        let appModel = AppModel(
            childRepository: childRepository,
            userIdentityRepository: userIdentityRepository,
            membershipRepository: membershipRepository,
            childSelectionStore: childSelectionStore,
            eventRepository: eventRepository,
            syncEngine: syncEngine,
            liveActivityManager: NoOpFeedLiveActivityManager(),
            liveActivityPreferenceStore: liveActivityPreferenceStore,
            localNotificationManager: NoOpLocalNotificationManager(),
            hapticFeedbackProvider: NoOpHapticFeedbackProvider()
        )
        let shareAcceptanceHandler = ShareAcceptanceHandler(
            syncEngine: syncEngine,
            onStartAcceptingShare: {
                appModel.beginAcceptingSharedChild()
            },
            onAcceptedShare: {
                appModel.completeAcceptingSharedChild()
            },
            onFailedToAcceptShare: { error in
                appModel.failAcceptingSharedChild(error)
            }
        )
        appModel.load()

        _ = processInfo
        return AppContainer(
            appModel: appModel,
            shareAcceptanceHandler: shareAcceptanceHandler
        )
    }()

    private init(
        appModel: AppModel,
        shareAcceptanceHandler: ShareAcceptanceHandler
    ) {
        self.appModel = appModel
        self.shareAcceptanceHandler = shareAcceptanceHandler
    }

    private static func seed(
        scenario: LaunchScenario,
        childRepository: SwiftDataChildRepository,
        userIdentityRepository: SwiftDataUserIdentityRepository,
        membershipRepository: SwiftDataMembershipRepository,
        childSelectionStore: UserDefaultsChildSelectionStore,
        eventRepository: SwiftDataEventRepository
    ) throws {
        try userIdentityRepository.resetAllData()

        switch scenario {
        case .activeCaregiver:
            let owner = try UserIdentity(
                displayName: "Sam Owner",
                cloudKitUserRecordName: "owner.preview.record"
            )
            let caregiver = try UserIdentity(
                displayName: "Jamie Caregiver",
                cloudKitUserRecordName: "caregiver.preview.record"
            )
            let child = try Child(name: "Robin", birthDate: .now, createdBy: owner.id)

            try userIdentityRepository.saveUser(owner)
            try userIdentityRepository.saveUser(caregiver)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try membershipRepository.saveMembership(Membership(
                childID: child.id,
                userID: caregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try userIdentityRepository.saveLocalUser(caregiver)
            childSelectionStore.saveSelectedChildID(child.id)
        case .ownerPreview:
            let owner = try UserIdentity(
                displayName: "Alex Parent",
                cloudKitUserRecordName: "owner.preview.record"
            )
            let activeCaregiver = try UserIdentity(
                displayName: "Taylor Night Feed",
                cloudKitUserRecordName: "caregiver.preview.record"
            )
            let removedCaregiver = try UserIdentity(
                displayName: "Jordan Former",
                cloudKitUserRecordName: "removed.preview.record"
            )
            let child = try Child(name: "Poppy", birthDate: .now, createdBy: owner.id)

            try userIdentityRepository.saveUser(owner)
            try userIdentityRepository.saveUser(activeCaregiver)
            try userIdentityRepository.saveUser(removedCaregiver)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try membershipRepository.saveMembership(Membership(
                childID: child.id,
                userID: activeCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try membershipRepository.saveMembership(Membership(
                childID: child.id,
                userID: removedCaregiver.id,
                role: .caregiver,
                status: .removed,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try userIdentityRepository.saveLocalUser(owner)
            childSelectionStore.saveSelectedChildID(child.id)
        case .futureActiveSleepPreview:
            let owner = try UserIdentity(
                displayName: "Alex Parent",
                cloudKitUserRecordName: "owner.preview.record"
            )
            let child = try Child(name: "Poppy", birthDate: .now, createdBy: owner.id)
            let sleepStart = Date(timeIntervalSinceNow: 3_600)

            try userIdentityRepository.saveUser(owner)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try userIdentityRepository.saveLocalUser(owner)
            childSelectionStore.saveSelectedChildID(child.id)

            let sleep = try SleepEvent(
                metadata: EventMetadata(
                    childID: child.id,
                    occurredAt: sleepStart,
                    createdAt: sleepStart,
                    createdBy: owner.id
                ),
                startedAt: sleepStart
            )

            try eventRepository.saveEvent(.sleep(sleep))
        case .mixedEventsPreview:
            let owner = try UserIdentity(
                displayName: "Alex Parent",
                cloudKitUserRecordName: "owner.preview.record"
            )
            let child = try Child(name: "Poppy", birthDate: .now, createdBy: owner.id)
            let feedTime = Date(timeIntervalSinceNow: -7_200)
            let sleepEnd = Date(timeIntervalSinceNow: -1_800)

            try userIdentityRepository.saveUser(owner)
            try childRepository.saveChild(child)
            try membershipRepository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try userIdentityRepository.saveLocalUser(owner)
            childSelectionStore.saveSelectedChildID(child.id)

            let bottleFeed = try BottleFeedEvent(
                metadata: EventMetadata(
                    childID: child.id,
                    occurredAt: feedTime,
                    createdAt: feedTime,
                    createdBy: owner.id
                ),
                amountMilliliters: 120,
                milkType: .formula
            )
            let sleep = try SleepEvent(
                metadata: EventMetadata(
                    childID: child.id,
                    occurredAt: sleepEnd,
                    createdAt: sleepEnd,
                    createdBy: owner.id
                ),
                startedAt: sleepEnd.addingTimeInterval(-1_800),
                endedAt: sleepEnd
            )

            try eventRepository.saveEvent(.bottleFeed(bottleFeed))
            try eventRepository.saveEvent(.sleep(sleep))
        }
    }
}

extension AppContainer {
    private struct LaunchConfiguration {
        let usesInMemoryStore: Bool
        let usesUnavailableCloudKitClient: Bool
        let usesNoOpLiveActivities: Bool
        let skipsLaunchSync: Bool
        let userDefaultsSuiteName: String?
        let scenario: LaunchScenario?

        init(processInfo: ProcessInfo) {
            let usesInMemoryStore = processInfo.arguments.contains("UI_TESTING")
            let isRunningTests = processInfo.environment["XCTestConfigurationFilePath"] != nil
            let scenario = LaunchScenario(rawValue: processInfo.environment["UI_TEST_SCENARIO"] ?? "")

            self.init(
                usesInMemoryStore: usesInMemoryStore,
                usesUnavailableCloudKitClient: usesInMemoryStore || isRunningTests,
                usesNoOpLiveActivities: usesInMemoryStore || isRunningTests,
                skipsLaunchSync: usesInMemoryStore || isRunningTests,
                userDefaultsSuiteName: usesInMemoryStore ? "BabyTrackerUITests" : nil,
                scenario: scenario
            )
        }

        init(
            usesInMemoryStore: Bool,
            usesUnavailableCloudKitClient: Bool = true,
            usesNoOpLiveActivities: Bool = true,
            skipsLaunchSync: Bool = false,
            userDefaultsSuiteName: String?,
            scenario: LaunchScenario?
        ) {
            self.usesInMemoryStore = usesInMemoryStore
            self.usesUnavailableCloudKitClient = usesUnavailableCloudKitClient
            self.usesNoOpLiveActivities = usesNoOpLiveActivities
            self.skipsLaunchSync = skipsLaunchSync
            self.userDefaultsSuiteName = userDefaultsSuiteName
            self.scenario = scenario
        }

        func makeUserDefaults() -> UserDefaults {
            guard let userDefaultsSuiteName else {
                return .standard
            }

            let userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
            userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
            return userDefaults
        }
    }

    private enum LaunchScenario: String {
        case activeCaregiver
        case futureActiveSleepPreview
        case mixedEventsPreview
        case ownerPreview
    }
}
