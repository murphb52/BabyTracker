import Foundation

@MainActor
public struct SaveBottleQuickAmountsUseCase: UseCase {
    public struct Input {
        public let child: Child
        /// `nil` resets to app defaults.
        public let amounts: [Int]?

        public init(child: Child, amounts: [Int]?) {
            self.child = child
            self.amounts = amounts
        }
    }

    private let childRepository: any ChildRepository

    public init(childRepository: any ChildRepository) {
        self.childRepository = childRepository
    }

    public func execute(_ input: Input) throws -> Child {
        let updated = input.child.updatingCustomBottleAmounts(input.amounts)
        try childRepository.saveChild(updated)
        return updated
    }
}
