import Foundation

@MainActor
public struct GetSleepStartSuggestionsUseCase: UseCase {
    public struct Input {
        public let childID: UUID

        public init(childID: UUID) {
            self.childID = childID
        }
    }

    public struct Suggestion {
        public let label: String
        public let date: Date

        public init(label: String, date: Date) {
            self.label = label
            self.date = date
        }
    }

    private let eventRepository: any EventRepository

    public init(eventRepository: any EventRepository) {
        self.eventRepository = eventRepository
    }

    public func execute(_ input: Input) throws -> [Suggestion] {
        let timeline = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)
        let timeFormatter = Date.FormatStyle(date: .omitted, time: .shortened)
        var suggestions: [Suggestion] = []

        if case let .bottleFeed(feed) = timeline.first(where: { if case .bottleFeed = $0 { true } else { false } }) {
            suggestions.append(Suggestion(
                label: "Last bottle at \(feed.metadata.occurredAt.formatted(timeFormatter))",
                date: feed.metadata.occurredAt
            ))
        }

        if case let .breastFeed(feed) = timeline.first(where: { if case .breastFeed = $0 { true } else { false } }) {
            suggestions.append(Suggestion(
                label: "Last feed at \(feed.metadata.occurredAt.formatted(timeFormatter))",
                date: feed.metadata.occurredAt
            ))
        }

        if case let .nappy(nappy) = timeline.first(where: { if case .nappy = $0 { true } else { false } }) {
            suggestions.append(Suggestion(
                label: "Last nappy at \(nappy.metadata.occurredAt.formatted(timeFormatter))",
                date: nappy.metadata.occurredAt
            ))
        }

        return suggestions
    }
}
