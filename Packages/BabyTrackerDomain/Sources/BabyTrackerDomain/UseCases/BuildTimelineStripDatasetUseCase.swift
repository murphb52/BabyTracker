import Foundation

@MainActor
public struct BuildTimelineStripDatasetUseCase {
    public static let defaultSlotMinutes = 5
    public static let defaultMinimumVisibleDays = 7

    private let slotMinutes: Int
    private let minimumVisibleDays: Int

    public init(
        slotMinutes: Int = BuildTimelineStripDatasetUseCase.defaultSlotMinutes,
        minimumVisibleDays: Int = BuildTimelineStripDatasetUseCase.defaultMinimumVisibleDays
    ) {
        self.slotMinutes = slotMinutes
        self.minimumVisibleDays = minimumVisibleDays
    }

    public func execute(
        events: [BabyEvent],
        calendar: Calendar,
        now: Date = .now
    ) -> TimelineStripDataset {
        let today = calendar.startOfDay(for: now)
        let minimumStartDay = calendar.date(
            byAdding: .day,
            value: -(minimumVisibleDays - 1),
            to: today
        ) ?? today

        let earliestEventStart = events
            .map(timelineStartDate(for:))
            .min()
            .map(calendar.startOfDay(for:))

        let firstDay = min(minimumStartDay, earliestEventStart ?? minimumStartDay)

        var columns: [TimelineStripDayColumn] = []
        var currentDay = firstDay

        while currentDay <= today {
            columns.append(
                TimelineStripDayColumn(
                    date: currentDay,
                    slots: Array(repeating: TimelineStripSlot(kind: nil), count: slotsPerDay)
                )
            )

            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else {
                break
            }
            currentDay = nextDay
        }

        for event in events {
            apply(event: event, to: &columns, calendar: calendar, now: now)
        }

        let todayIndex = columns.lastIndex(where: { calendar.isDateInToday($0.date) }) ?? max(0, columns.count - 1)

        return TimelineStripDataset(columns: columns, todayIndex: todayIndex)
    }

    private var slotsPerDay: Int {
        (24 * 60) / slotMinutes
    }

    private func apply(
        event: BabyEvent,
        to columns: inout [TimelineStripDayColumn],
        calendar: Calendar,
        now: Date
    ) {
        let eventStart = timelineStartDate(for: event)
        let eventEnd = max(eventStart, timelineEndDate(for: event, now: now))

        guard let firstIndex = columns.firstIndex(where: { day in
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: day.date) ?? day.date
            return dayEnd > eventStart
        }) else {
            return
        }

        for index in firstIndex..<columns.count {
            let dayStart = columns[index].date
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            if dayStart >= eventEnd {
                break
            }

            let visibleStart = max(dayStart, eventStart)
            let visibleEnd = min(dayEnd, eventEnd)

            guard visibleEnd > visibleStart else {
                continue
            }

            let startMinute = minuteOfDay(for: visibleStart, relativeTo: dayStart)
            let endMinute = max(startMinute + 1, minuteOfDay(for: visibleEnd, relativeTo: dayStart))
            let startSlot = max(0, startMinute / slotMinutes)
            let endSlot = min(slotsPerDay, (endMinute + (slotMinutes - 1)) / slotMinutes)

            guard startSlot < endSlot else {
                continue
            }

            var updatedSlots = columns[index].slots

            for slot in startSlot..<endSlot {
                let existingKind = updatedSlots[slot].kind
                if priority(of: event.kind) >= priority(of: existingKind) {
                    updatedSlots[slot] = TimelineStripSlot(kind: event.kind)
                }
            }

            columns[index] = TimelineStripDayColumn(
                date: columns[index].date,
                slots: updatedSlots
            )
        }
    }

    private func priority(of kind: BabyEventKind?) -> Int {
        switch kind {
        case .sleep:
            return 4
        case .breastFeed:
            return 3
        case .bottleFeed:
            return 2
        case .nappy:
            return 1
        case nil:
            return 0
        }
    }

    private func minuteOfDay(
        for date: Date,
        relativeTo dayStart: Date
    ) -> Int {
        let interval = date.timeIntervalSince(dayStart)
        return max(0, min(1_440, Int(interval / 60)))
    }

    private func timelineStartDate(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed):
            return feed.startedAt
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt
        case let .sleep(sleep):
            return sleep.startedAt
        case let .nappy(nappy):
            return nappy.metadata.occurredAt
        }
    }

    private func timelineEndDate(
        for event: BabyEvent,
        now: Date
    ) -> Date {
        switch event {
        case let .breastFeed(feed):
            return feed.endedAt ?? now
        case let .bottleFeed(feed):
            return feed.metadata.occurredAt.addingTimeInterval(TimeInterval(slotMinutes * 60))
        case let .sleep(sleep):
            return sleep.endedAt ?? now
        case let .nappy(nappy):
            return nappy.metadata.occurredAt.addingTimeInterval(TimeInterval(slotMinutes * 60))
        }
    }
}
