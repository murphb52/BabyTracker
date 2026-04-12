import Foundation

/// Attaches the local user's active membership to each child, skipping children
/// where no active membership exists. Results are sorted oldest-first by creation date.
@MainActor
public struct LoadChildSummariesUseCase: UseCase {
    public struct Input {
        public let children: [Child]
        public let userID: UUID

        public init(children: [Child], userID: UUID) {
            self.children = children
            self.userID = userID
        }
    }

    private let membershipRepository: any MembershipRepository

    public init(membershipRepository: any MembershipRepository) {
        self.membershipRepository = membershipRepository
    }

    public func execute(_ input: Input) throws -> [ChildSummary] {
        var summaries: [ChildSummary] = []

        for child in input.children {
            let memberships = try membershipRepository.loadMemberships(for: child.id)
            guard let membership = memberships.first(where: {
                $0.userID == input.userID && $0.status == .active
            }) else {
                continue
            }
            summaries.append(ChildSummary(child: child, membership: membership))
        }

        return summaries.sorted { $0.child.createdAt < $1.child.createdAt }
    }
}
