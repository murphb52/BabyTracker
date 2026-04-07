import BabyTrackerDomain
import Foundation

public struct RecentSleepEventViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let detailText: String
    public let timestampText: String
    public let editPayload: EditPayload

    public init?(event: BabyEvent) {
        guard case let .sleep(sleepEvent) = event,
              let endedAt = sleepEvent.endedAt else {
            return nil
        }

        id = sleepEvent.id
        title = BabyEventPresentation.title(for: event)

        let durationMinutes = max(
            1,
            Int(endedAt.timeIntervalSince(sleepEvent.startedAt) / 60)
        )
        let startTimeText = sleepEvent.startedAt.formatted(date: .omitted, time: .shortened)
        let endTimeText = endedAt.formatted(date: .omitted, time: .shortened)
        detailText = "\(DurationText.short(minutes: durationMinutes, minuteStyle: .word)) • \(startTimeText)-\(endTimeText)"
        timestampText = endedAt.formatted(
            date: .abbreviated,
            time: .shortened
        )
        editPayload = EditPayload(
            startedAt: sleepEvent.startedAt,
            endedAt: endedAt
        )
    }
}

extension RecentSleepEventViewState {
    public struct EditPayload: Equatable, Sendable {
        public let startedAt: Date
        public let endedAt: Date

        public init(
            startedAt: Date,
            endedAt: Date
        ) {
            self.startedAt = startedAt
            self.endedAt = endedAt
        }
    }
}
