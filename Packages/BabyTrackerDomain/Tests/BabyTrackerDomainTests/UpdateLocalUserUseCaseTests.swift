import Foundation
import Testing
@testable import BabyTrackerDomain

@MainActor
struct UpdateLocalUserUseCaseTests {
    @Test
    func updatesSavedLocalUserDisplayName() throws {
        let repository = InMemoryUserIdentityRepository()
        let existingUser = try UserIdentity(
            displayName: "Alex Parent",
            cloudKitUserRecordName: "icloud-user"
        )
        try repository.saveLocalUser(existingUser)

        let updatedUser = try UpdateLocalUserUseCase(
            userIdentityRepository: repository
        ).execute(.init(displayName: "Sam Parent"))

        #expect(updatedUser.displayName == "Sam Parent")
        #expect(updatedUser.cloudKitUserRecordName == "icloud-user")
        #expect(try repository.loadLocalUser()?.displayName == "Sam Parent")
    }

    @Test
    func throwsWhenNoLocalUserExists() {
        let repository = InMemoryUserIdentityRepository()

        #expect(throws: ChildProfileValidationError.insufficientPermissions) {
            try UpdateLocalUserUseCase(
                userIdentityRepository: repository
            ).execute(.init(displayName: "Sam Parent"))
        }
    }
}

@MainActor
private final class InMemoryUserIdentityRepository: UserIdentityRepository {
    private var localUser: UserIdentity?
    private var usersByID: [UUID: UserIdentity] = [:]

    func loadLocalUser() throws -> UserIdentity? {
        localUser
    }

    func saveLocalUser(_ user: UserIdentity) throws {
        localUser = user
        usersByID[user.id] = user
    }

    func loadUsers(for userIDs: [UUID]) throws -> [UserIdentity] {
        userIDs.compactMap { usersByID[$0] }
    }

    func saveUser(_ user: UserIdentity) throws {
        usersByID[user.id] = user
    }

    func removeLegacyPlaceholderCaregivers() throws {}

    func resetAllData() throws {
        localUser = nil
        usersByID.removeAll()
    }
}
