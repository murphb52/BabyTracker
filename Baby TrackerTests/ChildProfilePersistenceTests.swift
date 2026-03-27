import BabyTrackerDomain
import BabyTrackerPersistence
import Foundation
import Testing

@MainActor
struct ChildProfilePersistenceTests {
    @Test
    func savesAndReloadsLocalUserIdentity() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let user = try UserIdentity(displayName: "Alex Parent")

        try harness.userIdentityRepository.saveLocalUser(user)

        let loadedUser = try #require(try harness.userIdentityRepository.loadLocalUser())

        #expect(loadedUser == user)
    }

    @Test
    func savesChildAndOwnerMembershipAsActiveProfile() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Alex Parent")
        let child = try Child(name: "Poppy", createdBy: owner.id)

        try harness.userIdentityRepository.saveLocalUser(owner)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt))

        let activeChildren = try harness.childRepository.loadActiveChildren(for: owner.id)
        let memberships = try harness.membershipRepository.loadMemberships(for: child.id)

        #expect(activeChildren == [child])
        #expect(memberships.count == 1)
        #expect(memberships.first?.role == .owner)
        #expect(memberships.first?.status == .active)
    }

    @Test
    func persistsMembershipLifecycleAndArchiveState() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Owner")
        let caregiver = try UserIdentity(displayName: "Caregiver")
        var child = try Child(name: "Robin", createdBy: owner.id)
        let ownerMembership = Membership.owner(childID: child.id, userID: owner.id, createdAt: child.createdAt)
        let invitedMembership = Membership.invitedCaregiver(childID: child.id, userID: caregiver.id)

        try harness.userIdentityRepository.saveLocalUser(owner)
        try harness.userIdentityRepository.saveUser(caregiver)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(ownerMembership)
        try harness.membershipRepository.saveMembership(invitedMembership)

        let activeMembership = try invitedMembership.activated()
        try harness.membershipRepository.saveMembership(activeMembership)
        try harness.membershipRepository.saveMembership(try activeMembership.removed())

        child.isArchived = true
        try harness.childRepository.saveChild(child)

        let activeChildren = try harness.childRepository.loadActiveChildren(for: owner.id)
        let archivedChildren = try harness.childRepository.loadArchivedChildren(for: owner.id)
        let memberships = try harness.membershipRepository.loadMemberships(for: child.id)

        #expect(activeChildren.isEmpty)
        #expect(archivedChildren == [child])
        #expect(memberships.map(\.status) == [.active, .removed])

        child.isArchived = false
        try harness.childRepository.saveChild(child)

        let restoredChildren = try harness.childRepository.loadActiveChildren(for: owner.id)

        #expect(restoredChildren == [child])
    }

    @Test
    func savesChildPreferredFeedVolumeUnit() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Owner")
        let child = try Child(
            name: "Robin",
            createdBy: owner.id,
            preferredFeedVolumeUnit: .ounces
        )

        try harness.userIdentityRepository.saveLocalUser(owner)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(
            .owner(childID: child.id, userID: owner.id, createdAt: child.createdAt)
        )

        let loadedChild = try #require(try harness.childRepository.loadChild(id: child.id))

        #expect(loadedChild.preferredFeedVolumeUnit == .ounces)
    }

    @Test
    func savesSelectedChildIdentifier() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let childID = UUID()

        harness.childSelectionStore.saveSelectedChildID(childID)

        #expect(harness.childSelectionStore.loadSelectedChildID() == childID)
    }

    @Test
    func linksLocalUserToCanonicalCloudKitIdentity() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let localOwner = try UserIdentity(displayName: "Alex Parent")
        let canonicalOwner = try UserIdentity(
            displayName: "Cloud Alex",
            cloudKitUserRecordName: "owner.record"
        )
        let child = try Child(name: "Poppy", createdBy: localOwner.id)

        try harness.userIdentityRepository.saveUser(canonicalOwner)
        try harness.userIdentityRepository.saveLocalUser(localOwner)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(
            .owner(
                childID: child.id,
                userID: localOwner.id,
                createdAt: child.createdAt
            )
        )

        let linkedUser = try #require(
            try harness.userIdentityRepository.linkLocalUser(
                toCloudKitUserRecordName: "owner.record"
            )
        )
        let memberships = try harness.membershipRepository.loadMemberships(for: child.id)
        let activeChildren = try harness.childRepository.loadActiveChildren(for: canonicalOwner.id)

        #expect(linkedUser.id == canonicalOwner.id)
        #expect(linkedUser.displayName == localOwner.displayName)
        #expect(memberships.map(\.userID) == [canonicalOwner.id])
        #expect(activeChildren.count == 1)
        #expect(activeChildren.first?.id == child.id)
        #expect(activeChildren.first?.createdBy == canonicalOwner.id)
    }

    @Test
    func removesLegacyPlaceholderCaregiversWithoutCloudKitLinkage() throws {
        let harness = try RepositoryHarness()
        defer { harness.cleanUp() }

        let owner = try UserIdentity(displayName: "Alex Parent")
        let placeholderCaregiver = try UserIdentity(displayName: "Legacy Helper")
        let cloudLinkedCaregiver = try UserIdentity(
            displayName: "Cloud Helper",
            cloudKitUserRecordName: "helper.record"
        )
        let child = try Child(name: "Robin", createdBy: owner.id)

        try harness.userIdentityRepository.saveLocalUser(owner)
        try harness.userIdentityRepository.saveUser(placeholderCaregiver)
        try harness.userIdentityRepository.saveUser(cloudLinkedCaregiver)
        try harness.childRepository.saveChild(child)
        try harness.membershipRepository.saveMembership(
            .owner(
                childID: child.id,
                userID: owner.id,
                createdAt: child.createdAt
            )
        )
        try harness.membershipRepository.saveMembership(
            Membership(
                childID: child.id,
                userID: placeholderCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            )
        )
        try harness.membershipRepository.saveMembership(
            Membership(
                childID: child.id,
                userID: cloudLinkedCaregiver.id,
                role: .caregiver,
                status: .active,
                invitedAt: child.createdAt,
                acceptedAt: child.createdAt
            )
        )

        try harness.userIdentityRepository.removeLegacyPlaceholderCaregivers()

        let memberships = try harness.membershipRepository.loadMemberships(for: child.id)
        let remainingUsers = try harness.userIdentityRepository.loadUsers(
            for: [owner.id, placeholderCaregiver.id, cloudLinkedCaregiver.id]
        )

        #expect(memberships.count == 2)
        #expect(!memberships.contains(where: { $0.userID == placeholderCaregiver.id }))
        #expect(remainingUsers.contains(where: { $0.id == owner.id }))
        #expect(!remainingUsers.contains(where: { $0.id == placeholderCaregiver.id }))
        #expect(remainingUsers.contains(where: { $0.id == cloudLinkedCaregiver.id }))
    }
}

extension ChildProfilePersistenceTests {
    @MainActor
    private struct RepositoryHarness {
        let suiteName = "BabyTrackerTests.\(UUID().uuidString)"
        let userDefaults: UserDefaults
        let childRepository: SwiftDataChildRepository
        let userIdentityRepository: SwiftDataUserIdentityRepository
        let membershipRepository: SwiftDataMembershipRepository
        let childSelectionStore: UserDefaultsChildSelectionStore

        init() throws {
            let userDefaults = UserDefaults(suiteName: suiteName)!
            userDefaults.removePersistentDomain(forName: suiteName)
            let store = try BabyTrackerModelStore(isStoredInMemoryOnly: true)

            self.userDefaults = userDefaults
            self.childRepository = SwiftDataChildRepository(store: store)
            self.userIdentityRepository = SwiftDataUserIdentityRepository(store: store, userDefaults: userDefaults)
            self.membershipRepository = SwiftDataMembershipRepository(store: store)
            self.childSelectionStore = UserDefaultsChildSelectionStore(userDefaults: userDefaults)
        }

        func cleanUp() {
            userDefaults.removePersistentDomain(forName: suiteName)
        }
    }
}
