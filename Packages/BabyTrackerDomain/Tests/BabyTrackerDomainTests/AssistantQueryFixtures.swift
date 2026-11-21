import BabyTrackerDomain
import Foundation

/// Shared calendar, clock and event builders for the assistant query tests.
@MainActor
enum AssistantQueryFixtures {
    static let childID = UUID()

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// Saturday 15 June 2024, 14:00 UTC.
    static let now = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14))!

    static func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: now))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    static func metadata(at date: Date, isDeleted: Bool = false) -> EventMetadata {
        EventMetadata(childID: childID, occurredAt: date, createdBy: UUID(), isDeleted: isDeleted)
    }

    static func bottle(_ amount: Int, at date: Date, isDeleted: Bool = false) throws -> BabyEvent {
        .bottleFeed(try BottleFeedEvent(metadata: metadata(at: date, isDeleted: isDeleted), amountMilliliters: amount))
    }

    static func breastFeed(minutes: Int, endingAt end: Date) throws -> BabyEvent {
        let start = end.addingTimeInterval(TimeInterval(-minutes * 60))
        return .breastFeed(try BreastFeedEvent(metadata: metadata(at: end), side: .left, startedAt: start, endedAt: end))
    }

    static func sleep(from start: Date, minutes: Int?) throws -> BabyEvent {
        let end = minutes.map { start.addingTimeInterval(TimeInterval($0 * 60)) }
        return .sleep(try SleepEvent(metadata: metadata(at: end ?? start), startedAt: start, endedAt: end))
    }

    static func nappy(_ type: NappyType, at date: Date) throws -> BabyEvent {
        .nappy(try NappyEvent(metadata: metadata(at: date), type: type))
    }

    static func food(_ name: String, at date: Date) throws -> BabyEvent {
        .food(try FoodEvent(metadata: metadata(at: date), foodName: name, amount: 1, unit: .tablespoons))
    }
}

@MainActor
final class AssistantStubEventRepository: EventRepository {
    private let events: [BabyEvent]

    init(events: [BabyEvent]) {
        self.events = events
    }

    func saveEvent(_ event: BabyEvent) throws {}
    func loadEvent(id: UUID) throws -> BabyEvent? { nil }
    func loadTimeline(for childID: UUID, includingDeleted: Bool) throws -> [BabyEvent] { events }
    func loadEvents(for childID: UUID, on day: Date, calendar: Calendar, includingDeleted: Bool) throws -> [BabyEvent] { [] }
    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent? { nil }
    func softDeleteEvent(id: UUID, deletedAt: Date, deletedBy: UUID) throws {}
}
