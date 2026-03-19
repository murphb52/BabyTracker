//
//  Baby_TrackerTests.swift
//  Baby TrackerTests
//
//  Created by Brian Murphy on 19/03/2026.
//

import BabyTrackerDomain
import Foundation
import Testing

struct Baby_TrackerTests {
    @Test
    func ownerRoleCanManageCaregivers() {
        #expect(MembershipRole.owner.canManageCaregivers)
        #expect(!MembershipRole.caregiver.canManageCaregivers)
    }

    @Test
    func membershipStatusTracksSharedDataAccess() {
        #expect(!MembershipStatus.invited.hasSharedDataAccess)
        #expect(MembershipStatus.active.hasSharedDataAccess)
        #expect(!MembershipStatus.removed.hasSharedDataAccess)
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
            _ = try NappyEntry(type: .poo, intensity: .medium, pooColor: .brown)
        }

        #expect(throws: Never.self) {
            _ = try NappyEntry(type: .mixed, intensity: .high, pooColor: .green)
        }
    }
}
