import Foundation

@MainActor
public struct CreateLocalUserUseCase: UseCase {
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
        let user = try UserIdentity(displayName: input.displayName)
        try userIdentityRepository.saveLocalUser(user)
        hapticFeedbackProvider.play(.actionSucceeded)
        return user
    }
}
