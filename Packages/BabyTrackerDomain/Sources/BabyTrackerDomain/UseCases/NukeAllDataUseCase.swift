import Foundation

/// Describes the CloudKit operations the caller must perform before wiping local state.
public struct NukeAllDataIntent: Sendable {
    /// Children where the user is the owner — caller should delete each CloudKit zone.
    public let ownedChildIDs: [UUID]
    /// Children where the user is an active caregiver — caller should leave each share.
    public let caregiverChildIDs: [UUID]

    public init(ownedChildIDs: [UUID], caregiverChildIDs: [UUID]) {
        self.ownedChildIDs = ownedChildIDs
        self.caregiverChildIDs = caregiverChildIDs
    }
}

/// Classifies all children the local user has an active membership for into
/// owned and caregiver groups, returning the intent needed for full cleanup.
///
/// This use case has no side effects. The caller is responsible for:
/// 1. Leaving CloudKit shares for each `caregiverChildIDs` entry.
/// 2. Deleting the CloudKit zone for each `ownedChildIDs` entry.
/// 3. Calling `userIdentityRepository.resetAllData()` to wipe all local state,
///    including user identity.
///
/// Local CloudKit context (zone names) must still be intact when this use case
/// runs so that CloudKit operations in steps 1–2 can locate the correct zones.
@MainActor
public struct NukeAllDataUseCase: UseCase {
    public struct Input {
        public let localUserID: UUID

        public init(localUserID: UUID) {
            self.localUserID = localUserID
        }
    }

    public typealias Output = NukeAllDataIntent

    private let childRepository: any ChildRepository
    private let membershipRepository: any MembershipRepository

    public init(
        childRepository: any ChildRepository,
        membershipRepository: any MembershipRepository
    ) {
        self.childRepository = childRepository
        self.membershipRepository = membershipRepository
    }

    public func execute(_ input: Input) throws -> NukeAllDataIntent {
        let allChildren = try childRepository.loadAllChildren()
        var ownedIDs: [UUID] = []
        var caregiverIDs: [UUID] = []

        for child in allChildren {
            let memberships = try membershipRepository.loadMemberships(for: child.id)
            guard let mine = memberships.first(where: {
                $0.userID == input.localUserID && $0.status == .active
            }) else { continue }

            if mine.role == .owner {
                ownedIDs.append(child.id)
            } else {
                caregiverIDs.append(child.id)
            }
        }

        return NukeAllDataIntent(ownedChildIDs: ownedIDs, caregiverChildIDs: caregiverIDs)
    }
}
