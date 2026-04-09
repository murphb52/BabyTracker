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
        var dependencies = DependencyContainer()
        Self.registerDefaultDependencies(
            in: &dependencies,
            launchConfiguration: launchConfiguration
        )

        if let scenario = launchConfiguration.scenario {
            try? Self.seed(
                scenario: scenario,
                childRepository: dependencies.resolve(SwiftDataChildRepository.self),
                userIdentityRepository: dependencies.resolve(SwiftDataUserIdentityRepository.self),
                membershipRepository: dependencies.resolve(SwiftDataMembershipRepository.self),
                childSelectionStore: dependencies.resolve(UserDefaultsChildSelectionStore.self),
                eventRepository: dependencies.resolve(SwiftDataEventRepository.self)
            )
        }

        self = Self.build(from: dependencies, performLaunchSync: !launchConfiguration.skipsLaunchSync)
    }

    static let live = AppContainer()

    static let preview: AppContainer = {
        let launchConfiguration = LaunchConfiguration(
            usesInMemoryStore: true,
            userDefaultsSuiteName: "BabyTrackerPreview",
            scenario: .mixedEventsPreview
        )
        var dependencies = DependencyContainer()
        registerDefaultDependencies(in: &dependencies, launchConfiguration: launchConfiguration)

        try? seed(
            scenario: .mixedEventsPreview,
            childRepository: dependencies.resolve(SwiftDataChildRepository.self),
            userIdentityRepository: dependencies.resolve(SwiftDataUserIdentityRepository.self),
            membershipRepository: dependencies.resolve(SwiftDataMembershipRepository.self),
            childSelectionStore: dependencies.resolve(UserDefaultsChildSelectionStore.self),
            eventRepository: dependencies.resolve(SwiftDataEventRepository.self)
        )

        dependencies.register((any CloudKitClient).self, instance: UnavailableCloudKitClient())
        dependencies.register((any FeedLiveActivityManaging).self, instance: NoOpFeedLiveActivityManager())
        dependencies.register((any LocalNotificationManaging).self, instance: NoOpLocalNotificationManager())
        dependencies.register((any HapticFeedbackProviding).self, instance: NoOpHapticFeedbackProvider())

        return build(from: dependencies, performLaunchSync: true)
    }()

    private init(
        appModel: AppModel,
        shareAcceptanceHandler: ShareAcceptanceHandler
    ) {
        self.appModel = appModel
        self.shareAcceptanceHandler = shareAcceptanceHandler
    }

    private static func build(from dependencies: DependencyContainer, performLaunchSync: Bool) -> AppContainer {
        let appModel = dependencies.resolve(AppModel.self)
        let shareAcceptanceHandler = dependencies.resolve(ShareAcceptanceHandler.self)

        appModel.load(performLaunchSync: performLaunchSync)

        return AppContainer(
            appModel: appModel,
            shareAcceptanceHandler: shareAcceptanceHandler
        )
    }

    private static func registerDefaultDependencies(
        in dependencies: inout DependencyContainer,
        launchConfiguration: LaunchConfiguration
    ) {
        let userDefaults = launchConfiguration.makeUserDefaults()
        let store = try! BabyTrackerModelStore(
            isStoredInMemoryOnly: launchConfiguration.usesInMemoryStore
        )

        dependencies.register(UserDefaults.self, instance: userDefaults)
        dependencies.register(BabyTrackerModelStore.self, instance: store)

        dependencies.register(SwiftDataChildRepository.self) { _ in
            SwiftDataChildRepository(store: store)
        }
        dependencies.register(SwiftDataUserIdentityRepository.self) { container in
            SwiftDataUserIdentityRepository(
                store: store,
                userDefaults: container.resolve(UserDefaults.self)
            )
        }
        dependencies.register(SwiftDataMembershipRepository.self) { _ in
            SwiftDataMembershipRepository(store: store)
        }
        dependencies.register(UserDefaultsChildSelectionStore.self) { container in
            UserDefaultsChildSelectionStore(userDefaults: container.resolve(UserDefaults.self))
        }
        dependencies.register(SwiftDataEventRepository.self) { _ in
            SwiftDataEventRepository(store: store)
        }
        dependencies.register(SwiftDataSyncStateRepository.self) { _ in
            SwiftDataSyncStateRepository(store: store)
        }
        dependencies.register(SwiftDataCloudKitRecordMetadataRepository.self) { _ in
            SwiftDataCloudKitRecordMetadataRepository(store: store)
        }
        dependencies.register(UserDefaultsLiveActivityPreferenceStore.self) { container in
            UserDefaultsLiveActivityPreferenceStore(userDefaults: container.resolve(UserDefaults.self))
        }

        dependencies.register((any CloudKitClient).self) { _ in
            launchConfiguration.usesUnavailableCloudKitClient ?
                UnavailableCloudKitClient() :
                LiveCloudKitClient()
        }
        dependencies.register((any FeedLiveActivityManaging).self) { _ in
            launchConfiguration.usesNoOpLiveActivities ?
                NoOpFeedLiveActivityManager() :
                FeedLiveActivityManager()
        }
        dependencies.register((any LocalNotificationManaging).self) { _ in
            launchConfiguration.usesUnavailableCloudKitClient ?
                NoOpLocalNotificationManager() :
                SystemLocalNotificationManager()
        }
        dependencies.register((any HapticFeedbackProviding).self, instance: SystemHapticFeedbackProvider())

        dependencies.register(CloudKitSyncEngine.self) { container in
            CloudKitSyncEngine(
                childRepository: container.resolve(SwiftDataChildRepository.self),
                userIdentityRepository: container.resolve(SwiftDataUserIdentityRepository.self),
                membershipRepository: container.resolve(SwiftDataMembershipRepository.self),
                eventRepository: container.resolve(SwiftDataEventRepository.self),
                syncStateRepository: container.resolve(SwiftDataSyncStateRepository.self),
                recordMetadataRepository: container.resolve(SwiftDataCloudKitRecordMetadataRepository.self),
                client: container.resolve((any CloudKitClient).self)
            )
        }

        dependencies.register(AppModel.self) { container in
            AppModel(
                childRepository: container.resolve(SwiftDataChildRepository.self),
                userIdentityRepository: container.resolve(SwiftDataUserIdentityRepository.self),
                membershipRepository: container.resolve(SwiftDataMembershipRepository.self),
                childSelectionStore: container.resolve(UserDefaultsChildSelectionStore.self),
                eventRepository: container.resolve(SwiftDataEventRepository.self),
                syncEngine: container.resolve(CloudKitSyncEngine.self),
                liveActivityManager: container.resolve((any FeedLiveActivityManaging).self),
                liveActivityPreferenceStore: container.resolve(UserDefaultsLiveActivityPreferenceStore.self),
                localNotificationManager: container.resolve((any LocalNotificationManaging).self),
                hapticFeedbackProvider: container.resolve((any HapticFeedbackProviding).self)
            )
        }

        dependencies.register(ShareAcceptanceHandler.self) { container in
            let model = container.resolve(AppModel.self)
            return ShareAcceptanceHandler(
                syncEngine: container.resolve(CloudKitSyncEngine.self),
                onStartAcceptingShare: {
                    model.beginAcceptingSharedChild()
                },
                onAcceptedShare: {
                    model.completeAcceptingSharedChild()
                },
                onFailedToAcceptShare: { error in
                    model.failAcceptingSharedChild(error)
                }
            )
        }
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

    private final class DependencyContainer {
        private typealias Factory = (DependencyContainer) -> Any

        private var factories: [ObjectIdentifier: Factory] = [:]
        private var instances: [ObjectIdentifier: Any] = [:]

        func register<Dependency>(_ type: Dependency.Type, factory: @escaping (DependencyContainer) -> Dependency) {
            let key = ObjectIdentifier(type)
            factories[key] = { container in
                factory(container)
            }
        }

        func register<Dependency>(_ type: Dependency.Type, instance: Dependency) {
            let key = ObjectIdentifier(type)
            instances[key] = instance
        }

        func resolve<Dependency>(_ type: Dependency.Type) -> Dependency {
            let key = ObjectIdentifier(type)

            if let instance = instances[key] as? Dependency {
                return instance
            }

            guard let factory = factories[key] else {
                preconditionFailure("No dependency registered for \(type)")
            }

            let dependency = factory(self)
            guard let resolved = dependency as? Dependency else {
                preconditionFailure("Registered dependency for \(type) has an unexpected type.")
            }

            instances[key] = resolved
            return resolved
        }
    }
}
