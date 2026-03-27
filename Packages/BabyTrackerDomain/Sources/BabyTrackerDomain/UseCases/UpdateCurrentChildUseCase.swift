import Foundation

@MainActor
public struct UpdateCurrentChildUseCase: UseCase {
    public struct Input {
        public let child: Child
        public let name: String
        public let birthDate: Date?
        public let membership: Membership
        public let imageData: Data?
        public let preferredFeedVolumeUnit: FeedVolumeUnit

        public init(
            child: Child,
            name: String,
            birthDate: Date?,
            membership: Membership,
            imageData: Data? = nil,
            preferredFeedVolumeUnit: FeedVolumeUnit
        ) {
            self.child = child
            self.name = name
            self.birthDate = birthDate
            self.membership = membership
            self.imageData = imageData
            self.preferredFeedVolumeUnit = preferredFeedVolumeUnit
        }
    }

    private let childRepository: any ChildRepository

    public init(childRepository: any ChildRepository) {
        self.childRepository = childRepository
    }

    public func execute(_ input: Input) throws -> Child {
        guard ChildAccessPolicy.canPerform(.editChild, membership: input.membership) else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let updatedChild = try input.child.updating(
            name: input.name,
            birthDate: input.birthDate,
            imageData: input.imageData,
            preferredFeedVolumeUnit: input.preferredFeedVolumeUnit
        )
        try childRepository.saveChild(updatedChild)
        return updatedChild
    }
}
