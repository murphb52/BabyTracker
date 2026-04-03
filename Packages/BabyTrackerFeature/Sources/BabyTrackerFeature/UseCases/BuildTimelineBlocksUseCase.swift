import BabyTrackerDomain
import Foundation

/// Converts a list of events for a given day into positioned
/// `TimelineEventBlockViewState` values with lane-assignment for overlapping
/// events. This encapsulates all of the timeline layout maths that was
/// previously spread across several private helpers in `AppModel`.
public enum BuildTimelineBlocksUseCase {
    public static func execute(
        events: [BabyEvent],
        child: Child,
        day: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [TimelineEventBlockViewState] {
        let dayStart = normalizedDay(for: day, calendar: calendar)
        let blocks = events.map { event in
            makeBlock(from: event, child: child, dayStart: dayStart, calendar: calendar)
        }
        return assignLayout(to: blocks)
    }

    // MARK: - Block construction

    private static func makeBlock(
        from event: BabyEvent,
        child: Child,
        dayStart: Date,
        calendar: Calendar
    ) -> TimelineEventBlockViewState {
        let startMinute = visibleStartMinute(for: event, dayStart: dayStart, calendar: calendar)
        let endMinute = visibleEndMinute(for: event, dayStart: dayStart, startMinute: startMinute, calendar: calendar)

        switch event {
        case let .breastFeed(feed):
            let durationMinutes = max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            return TimelineEventBlockViewState(
                id: feed.id,
                kind: .breastFeed,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(
                    for: event,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                ) ?? "",
                timeText: "\(shortTimeText(for: feed.startedAt))-\(shortTimeText(for: feed.endedAt))",
                compactText: compactText(for: event, child: child),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editBreastFeed(
                    durationMinutes: durationMinutes,
                    endTime: feed.endedAt,
                    side: feed.side,
                    leftDurationSeconds: feed.leftDurationSeconds,
                    rightDurationSeconds: feed.rightDurationSeconds
                )
            )
        case let .bottleFeed(feed):
            return TimelineEventBlockViewState(
                id: feed.id,
                kind: .bottleFeed,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(
                    for: event,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                ) ?? "",
                timeText: shortTimeText(for: feed.metadata.occurredAt),
                compactText: compactText(for: event, child: child),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editBottleFeed(
                    amountMilliliters: feed.amountMilliliters,
                    occurredAt: feed.metadata.occurredAt,
                    milkType: feed.milkType
                )
            )
        case let .sleep(sleep):
            if let endedAt = sleep.endedAt {
                return TimelineEventBlockViewState(
                    id: sleep.id,
                    kind: .sleep,
                    title: BabyEventPresentation.title(for: event),
                    detailText: BabyEventPresentation.detailText(
                        for: event,
                        preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                    ) ?? "",
                    timeText: "\(shortTimeText(for: sleep.startedAt))-\(shortTimeText(for: endedAt))",
                    compactText: compactText(for: event, child: child),
                    startMinute: startMinute,
                    endMinute: endMinute,
                    laneIndex: 0,
                    laneCount: 1,
                    actionPayload: .editSleep(startedAt: sleep.startedAt, endedAt: endedAt)
                )
            }
            return TimelineEventBlockViewState(
                id: sleep.id,
                kind: .sleep,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(
                    for: event,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                ) ?? "",
                timeText: "Started \(shortTimeText(for: sleep.startedAt))",
                compactText: compactText(for: event, child: child),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .endSleep(startedAt: sleep.startedAt)
            )
        case let .nappy(nappy):
            return TimelineEventBlockViewState(
                id: nappy.id,
                kind: .nappy,
                title: BabyEventPresentation.title(for: event),
                detailText: BabyEventPresentation.detailText(
                    for: event,
                    preferredFeedVolumeUnit: child.preferredFeedVolumeUnit
                ) ?? "",
                timeText: shortTimeText(for: nappy.metadata.occurredAt),
                compactText: compactText(for: event, child: child),
                startMinute: startMinute,
                endMinute: endMinute,
                laneIndex: 0,
                laneCount: 1,
                actionPayload: .editNappy(
                    type: nappy.type,
                    occurredAt: nappy.metadata.occurredAt,
                    peeVolume: nappy.peeVolume,
                    pooVolume: nappy.pooVolume,
                    pooColor: nappy.pooColor
                )
            )
        }
    }

    // MARK: - Lane assignment

    private static func assignLayout(
        to blocks: [TimelineEventBlockViewState]
    ) -> [TimelineEventBlockViewState] {
        var laneEndMinutes: [Int] = []
        var laneIndexesByID: [UUID: Int] = [:]

        for block in blocks {
            if let laneIndex = laneEndMinutes.firstIndex(where: { block.startMinute >= $0 }) {
                laneEndMinutes[laneIndex] = block.endMinute
                laneIndexesByID[block.id] = laneIndex
            } else {
                laneIndexesByID[block.id] = laneEndMinutes.count
                laneEndMinutes.append(block.endMinute)
            }
        }

        return blocks.map { block in
            let laneIndex = laneIndexesByID[block.id] ?? 0
            let laneCount = maxConcurrentLanes(for: block, within: blocks)
            return block.updatingLayout(laneIndex: laneIndex, laneCount: laneCount)
        }
    }

    private static func maxConcurrentLanes(
        for block: TimelineEventBlockViewState,
        within blocks: [TimelineEventBlockViewState]
    ) -> Int {
        let candidateMinutes = blocks
            .filter { $0.endMinute > block.startMinute && $0.startMinute < block.endMinute }
            .map(\.startMinute) + [block.startMinute]

        return candidateMinutes.reduce(into: 1) { currentMax, minute in
            let count = blocks.count { $0.startMinute <= minute && $0.endMinute > minute }
            currentMax = max(currentMax, count)
        }
    }

    // MARK: - Minute positioning

    private static func visibleStartMinute(
        for event: BabyEvent,
        dayStart: Date,
        calendar: Calendar
    ) -> Int {
        let visibleStart = max(startDate(for: event), dayStart)
        return minuteOfDay(for: visibleStart, relativeTo: dayStart)
    }

    private static func visibleEndMinute(
        for event: BabyEvent,
        dayStart: Date,
        startMinute: Int,
        calendar: Calendar
    ) -> Int {
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let minimumDurationMinutes = 20
        let visibleEnd = min(endDate(for: event), dayEnd)
        let unclampedMinute = minuteOfDay(for: visibleEnd, relativeTo: dayStart)
        let minimumEndMinute = startMinute + minimumDurationMinutes
        return min(1_440, max(unclampedMinute, minimumEndMinute))
    }

    private static func minuteOfDay(for date: Date, relativeTo dayStart: Date) -> Int {
        max(0, min(1_440, Int(date.timeIntervalSince(dayStart) / 60)))
    }

    private static func startDate(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed): return feed.startedAt
        case let .bottleFeed(feed): return feed.metadata.occurredAt
        case let .sleep(sleep): return sleep.startedAt
        case let .nappy(nappy): return nappy.metadata.occurredAt
        }
    }

    private static func endDate(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed): return feed.endedAt
        case let .bottleFeed(feed): return feed.metadata.occurredAt
        case let .sleep(sleep): return sleep.endedAt ?? Date()
        case let .nappy(nappy): return nappy.metadata.occurredAt
        }
    }

    // MARK: - Formatting

    private static func shortTimeText(for date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private static func compactText(for event: BabyEvent, child: Child) -> String {
        switch event {
        case let .breastFeed(feed):
            let minutes = max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            return "\(minutes) min"
        case let .bottleFeed(feed):
            return FeedVolumeConverter.format(
                amountMilliliters: feed.amountMilliliters,
                in: child.preferredFeedVolumeUnit
            )
        case let .sleep(sleep):
            guard let endedAt = sleep.endedAt else { return "Sleep" }
            let minutes = max(1, Int(endedAt.timeIntervalSince(sleep.startedAt) / 60))
            return "\(minutes) min"
        case let .nappy(nappy):
            switch nappy.type {
            case .dry: return "Dry"
            case .wee: return "Wee"
            case .poo: return "Poo"
            case .mixed: return "Mixed"
            }
        }
    }

    // MARK: - Date helpers

    static func normalizedDay(for date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }
}
