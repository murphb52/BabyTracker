import BabyTrackerDomain
import Foundation
import Testing

struct ChildProfileDomainTests {
    @Test
    func childNameCannotBeBlank() {
        #expect(throws: ChildProfileValidationError.emptyChildName) {
            _ = try Child(name: "   ", createdBy: UUID())
        }
    }

    @Test
    func caregiverNameCannotBeBlank() {
        #expect(throws: ChildProfileValidationError.emptyCaregiverName) {
            _ = try UserIdentity(displayName: "\n")
        }
    }

    @Test
    func ownerPermissionsAreRestrictedToActiveOwners() {
        let childID = UUID()
        let owner = Membership.owner(childID: childID, userID: UUID())
        let caregiver = Membership(
            childID: childID,
            userID: UUID(),
            role: .caregiver,
            status: .active,
            invitedAt: .now,
            acceptedAt: .now
        )

        #expect(ChildAccessPolicy.canPerform(.editChild, membership: owner))
        #expect(ChildAccessPolicy.canPerform(.inviteCaregiver, membership: owner))
        #expect(ChildAccessPolicy.canPerform(.logEvent, membership: owner))
        #expect(!ChildAccessPolicy.canPerform(.editChild, membership: caregiver))
        #expect(!ChildAccessPolicy.canPerform(.removeCaregiver, membership: caregiver))
        #expect(ChildAccessPolicy.canPerform(.viewChild, membership: caregiver))
        #expect(ChildAccessPolicy.canPerform(.logEvent, membership: caregiver))
    }

    @Test
    func caregiverCannotMoveFromRemovedBackToActiveWithoutNewInvite() throws {
        let invited = Membership.invitedCaregiver(
            childID: UUID(),
            userID: UUID()
        )
        let removed = try invited.removed()

        #expect(throws: ChildProfileValidationError.invalidMembershipTransition(from: .removed, to: .active)) {
            _ = try removed.activated()
        }
    }

    @Test
    func lastOwnerCannotBeRemoved() {
        let owner = Membership.owner(childID: UUID(), userID: UUID())

        #expect(throws: ChildProfileValidationError.cannotRemoveLastOwner) {
            try MembershipValidator.validateRemoval(of: owner, within: [owner])
        }
    }

    @Test
    func bottleFeedsCanOmitMilkType() {
        let draft = BottleFeedDraft(amountMilliliters: 120)

        #expect(draft.amountMilliliters == 120)
        #expect(draft.milkType == nil)
    }

    @Test
    func pooColorRequiresPooOrMixedNappyTypes() {
        #expect(throws: NappyEntryError.pooColorRequiresPooOrMixed) {
            try NappyEntry(type: .dry, pooColor: .yellow)
        }

        #expect(throws: NappyEntryError.pooColorRequiresPooOrMixed) {
            try NappyEntry(type: .wee, pooColor: .mustard)
        }

        #expect(throws: Never.self) {
            _ = try NappyEntry(type: .poo, pooVolume: .medium, pooColor: .brown)
        }

        #expect(throws: Never.self) {
            _ = try NappyEntry(type: .mixed, pooVolume: .heavy, pooColor: .green)
        }
    }
}
