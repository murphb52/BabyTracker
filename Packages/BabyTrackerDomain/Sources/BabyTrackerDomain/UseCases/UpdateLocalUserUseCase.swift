import Foundation

@MainActor
public struct UpdateLocalUserUseCase: UseCase {
    public struct Input {
        public let displayName: String

        public init(displayName: String) {
            self.displayName = displayName
        }
    }

    private let userIdentityRepository: any UserIdentityRepository
    private let hapticFeedbackProvider: any HapticFeedbackProviding

    public init(
        userIdentityRepository: any UserIdentityRepository,
        hapticFeedbackProvider: any HapticFeedbackProviding = NoOpHapticFeedbackProvider()
    ) {
        self.userIdentityRepository = userIdentityRepository
        self.hapticFeedbackProvider = hapticFeedbackProvider
    }

    public func execute(_ input: Input) throws -> UserIdentity {
        guard let localUser = try userIdentityRepository.loadLocalUser() else {
            throw ChildProfileValidationError.insufficientPermissions
        }

        let updatedUser = try localUser.updating(
            displayName: input.displayName,
            cloudKitUserRecordName: localUser.cloudKitUserRecordName
        )
        try userIdentityRepository.saveLocalUser(updatedUser)
        hapticFeedbackProvider.play(.actionSucceeded)
        return updatedUser
    }
}
