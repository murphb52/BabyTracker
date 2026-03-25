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

    public init(userIdentityRepository: any UserIdentityRepository) {
        self.userIdentityRepository = userIdentityRepository
    }

    public func execute(_ input: Input) throws -> UserIdentity {
        let user = try UserIdentity(displayName: input.displayName)
        try userIdentityRepository.saveLocalUser(user)
        return user
    }
}
