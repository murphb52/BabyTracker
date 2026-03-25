import Foundation

@MainActor
public protocol EventRepository: AnyObject {
    func saveEvent(_ event: BabyEvent) throws
    func loadEvent(id: UUID) throws -> BabyEvent?
    func loadTimeline(
        for childID: UUID,
        includingDeleted: Bool
    ) throws -> [BabyEvent]
    func loadEvents(
        for childID: UUID,
        on day: Date,
        calendar: Calendar,
        includingDeleted: Bool
    ) throws -> [BabyEvent]
    func loadActiveSleepEvent(for childID: UUID) throws -> SleepEvent?
    func softDeleteEvent(
        id: UUID,
        deletedAt: Date,
        deletedBy: UUID
    ) throws
}
