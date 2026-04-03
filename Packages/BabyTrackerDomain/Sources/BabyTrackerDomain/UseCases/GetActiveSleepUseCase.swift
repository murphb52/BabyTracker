import Foundation

@MainActor
public struct GetActiveSleepUseCase: UseCase {
    public struct Input {
        public let childID: UUID

        public init(childID: UUID) {
            self.childID = childID
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> SleepEvent? {
        try eventRepository.loadActiveSleepEvent(for: input.childID)
    }
}
