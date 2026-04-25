import Foundation

/// Returns up to two bottle amounts the parent tends to log at the current time of day,
/// based on the past seven days of history within a ±2-hour window of the reference time.
@MainActor
public struct FetchSmartBottleAmountsUseCase: UseCase {
    public struct Input {
        public let childID: UUID
        public let referenceTime: Date

        public init(childID: UUID, referenceTime: Date) {
            self.childID = childID
            self.referenceTime = referenceTime
        }
    }

    private let eventRepository: any EventRepository
    private let calendar: Calendar

    public init(eventRepository: any EventRepository, calendar: Calendar = .current) {
        self.eventRepository = eventRepository
        self.calendar = calendar
    }

    public func execute(_ input: Input) throws -> [Int] {
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: input.referenceTime) else {
            return []
        }

        let timeline = try eventRepository.loadTimeline(for: input.childID, includingDeleted: false)
        let refMinutes = minutesFromMidnight(input.referenceTime)

        var countByAmount: [Int: Int] = [:]
        for event in timeline {
            guard case let .bottleFeed(feed) = event else { continue }
            let occurredAt = feed.metadata.occurredAt
            guard occurredAt >= sevenDaysAgo else { continue }
            guard isWithinWindow(minutesFromMidnight(occurredAt), of: refMinutes) else { continue }
            countByAmount[feed.amountMilliliters, default: 0] += 1
        }

        return countByAmount
            .sorted { $0.value > $1.value }
            .prefix(2)
            .map(\.key)
    }

    private func minutesFromMidnight(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func isWithinWindow(_ eventMinutes: Int, of refMinutes: Int) -> Bool {
        let diff = abs(eventMinutes - refMinutes)
        let wrappedDiff = min(diff, 1440 - diff)
        return wrappedDiff <= 120
    }
}
