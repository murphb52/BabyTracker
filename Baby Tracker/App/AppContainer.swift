import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerPersistence
import Foundation

@MainActor
struct AppContainer {
    let appModel: Stage1AppModel

    init(processInfo: ProcessInfo = .processInfo) {
        let launchConfiguration = LaunchConfiguration(processInfo: processInfo)
        let userDefaults = launchConfiguration.makeUserDefaults()
        let repository = try! SwiftDataChildProfileRepository(
            isStoredInMemoryOnly: launchConfiguration.usesInMemoryStore,
            userDefaults: userDefaults
        )

        if let scenario = launchConfiguration.scenario {
            try? Self.seed(scenario: scenario, repository: repository)
        }

        let appModel = Stage1AppModel(repository: repository)
        appModel.load()

        self.appModel = appModel
    }

    static let live = AppContainer()

    static let preview: AppContainer = {
        let processInfo = ProcessInfo.processInfo
        let launchConfiguration = LaunchConfiguration(
            usesInMemoryStore: true,
            userDefaultsSuiteName: "BabyTrackerPreview",
            scenario: .ownerPreview
        )
        let userDefaults = launchConfiguration.makeUserDefaults()
        let repository = try! SwiftDataChildProfileRepository(
            isStoredInMemoryOnly: true,
            userDefaults: userDefaults
        )

        try? seed(scenario: .ownerPreview, repository: repository)

        let appModel = Stage1AppModel(repository: repository)
        appModel.load()

        _ = processInfo
        return AppContainer(appModel: appModel)
    }()

    private init(appModel: Stage1AppModel) {
        self.appModel = appModel
    }

    private static func seed(
        scenario: LaunchScenario,
        repository: SwiftDataChildProfileRepository
    ) throws {
        try repository.resetAllData()

        switch scenario {
        case .activeCaregiver:
            let owner = try UserIdentity(displayName: "Sam Owner")
            let caregiver = try UserIdentity(displayName: "Jamie Caregiver")
            let child = try Child(name: "Robin", birthDate: .now, createdBy: owner.id)

            try repository.saveUser(owner)
            try repository.saveUser(caregiver)
            try repository.saveChild(child)
            try repository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try repository.saveMembership(Membership(
                childID: child.id,
                userID: caregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try repository.saveLocalUser(caregiver)
            repository.saveSelectedChildID(child.id)
        case .ownerPreview:
            let owner = try UserIdentity(displayName: "Alex Parent")
            let activeCaregiver = try UserIdentity(displayName: "Taylor Night Feed")
            let invitedCaregiver = try UserIdentity(displayName: "Morgan Invite")
            let removedCaregiver = try UserIdentity(displayName: "Jordan Former")
            let child = try Child(name: "Poppy", birthDate: .now, createdBy: owner.id)

            try repository.saveUser(owner)
            try repository.saveUser(activeCaregiver)
            try repository.saveUser(invitedCaregiver)
            try repository.saveUser(removedCaregiver)
            try repository.saveChild(child)
            try repository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))
            try repository.saveMembership(Membership(
                childID: child.id,
                userID: activeCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try repository.saveMembership(.invitedCaregiver(childID: child.id, userID: invitedCaregiver.id))
            try repository.saveMembership(Membership(
                childID: child.id,
                userID: removedCaregiver.id,
                role: .caregiver,
                status: .removed,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            ))
            try repository.saveLocalUser(owner)
            repository.saveSelectedChildID(child.id)
        }
    }
}

extension AppContainer {
    private struct LaunchConfiguration {
        let usesInMemoryStore: Bool
        let userDefaultsSuiteName: String?
        let scenario: LaunchScenario?

        init(processInfo: ProcessInfo) {
            let usesInMemoryStore = processInfo.arguments.contains("UI_TESTING")
            let scenario = LaunchScenario(rawValue: processInfo.environment["UI_TEST_SCENARIO"] ?? "")

            self.init(
                usesInMemoryStore: usesInMemoryStore,
                userDefaultsSuiteName: usesInMemoryStore ? "BabyTrackerUITests" : nil,
                scenario: scenario
            )
        }

        init(
            usesInMemoryStore: Bool,
            userDefaultsSuiteName: String?,
            scenario: LaunchScenario?
        ) {
            self.usesInMemoryStore = usesInMemoryStore
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
        case ownerPreview
    }
}
