import Foundation

@MainActor
public struct BuildTimelineDayGridDatasetUseCase {
    public static let defaultSlotMinutes = 15

    private let slotMinutes: Int

    public init(slotMinutes: Int = BuildTimelineDayGridDatasetUseCase.defaultSlotMinutes) {
        self.slotMinutes = slotMinutes
    }

    public func execute(
        events: [BabyEvent],
        day: Date,
        calendar: Calendar,
        now: Date = .now
    ) -> TimelineDayGridDataset {
        // Normalize the requested day once so every downstream calculation uses
        // the same inclusive start and exclusive end boundary.
        let normalizedDay = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: normalizedDay) ?? normalizedDay

        // Convert each event into a grid placement only if some portion of the
        // event is visible on the selected day, then bucket those placements by
        // event-type column before running the merge pass.
        let placementsByColumn = Dictionary(grouping: events.compactMap {
            placementInput(for: $0, dayStart: normalizedDay, dayEnd: dayEnd, now: now)
        }, by: \.columnKind)

        let columns = TimelineDayGridColumnKind.allCases.map { columnKind in
            TimelineDayGridColumn(
                kind: columnKind,
                placements: mergePlacements(
                    placementsByColumn[columnKind] ?? []
                )
            )
        }

        return TimelineDayGridDataset(
            day: normalizedDay,
            slotMinutes: slotMinutes,
            columns: columns
        )
    }

    private func mergePlacements(
        _ placements: [PlacementInput]
    ) -> [TimelineDayGridPlacement] {
        // Sort by slot coverage first so we can do a single left-to-right pass
        // and only ever compare the current placement with the last merged one.
        let sortedPlacements = placements.sorted {
            if $0.startSlotIndex != $1.startSlotIndex {
                return $0.startSlotIndex < $1.startSlotIndex
            }

            if $0.endSlotIndex != $1.endSlotIndex {
                return $0.endSlotIndex < $1.endSlotIndex
            }

            return $0.eventStart < $1.eventStart
        }

        var mergedPlacements: [PlacementInput] = []

        for placement in sortedPlacements {
            guard let lastPlacement = mergedPlacements.last else {
                mergedPlacements.append(placement)
                continue
            }

            // Placements are already grouped by column before this method runs,
            // so "overlap" here only means overlap within the same event-type
            // column. Events that merely touch on a boundary (one ending at
            // slot 20 and the next starting at 20) are kept separate.
            if placement.startSlotIndex < lastPlacement.endSlotIndex {
                var combined = lastPlacement
                combined.startSlotIndex = min(lastPlacement.startSlotIndex, placement.startSlotIndex)
                combined.endSlotIndex = max(lastPlacement.endSlotIndex, placement.endSlotIndex)

                // Preserve every underlying event so the UI can later show a
                // grouped summary or drill into the individual events.
                combined.events.append(contentsOf: placement.events)
                combined.events.sort { $0.start < $1.start }
                mergedPlacements[mergedPlacements.count - 1] = combined
            } else {
                mergedPlacements.append(placement)
            }
        }

        return mergedPlacements.map { placement in
            TimelineDayGridPlacement(
                columnKind: placement.columnKind,
                startSlotIndex: placement.startSlotIndex,
                endSlotIndex: placement.endSlotIndex,
                eventIDs: placement.events.map(\.id)
            )
        }
    }

    private func placementInput(
        for event: BabyEvent,
        dayStart: Date,
        dayEnd: Date,
        now: Date
    ) -> PlacementInput? {
        // First clip the event to the visible day. Events entirely outside the
        // day produce an empty interval and are dropped below.
        let interval = visibleInterval(for: event, dayStart: dayStart, dayEnd: dayEnd, now: now)

        guard interval.end > interval.start else {
            return nil
        }

        let slotsPerDay = (24 * 60) / slotMinutes

        // The grid is laid out in slot indexes, not raw minutes. Start rounds
        // down so an event beginning at 09:07 still appears in the 09:00 slot.
        let startMinute = max(0, Int(interval.start.timeIntervalSince(dayStart) / 60))
        let startSlotIndex = min(slotsPerDay, max(0, startMinute / slotMinutes))
        let endSlotIndex: Int

        if occupiesSingleSlot(event) {
            // Point-in-time events always claim exactly one slot so they remain
            // visible even when they occur exactly on a slot boundary.
            endSlotIndex = min(slotsPerDay, startSlotIndex + 1)
        } else {
            // Duration events round their end upward so partial-slot coverage is
            // still visible in the grid.
            let endMinute = max(startMinute + 1, Int(ceil(interval.end.timeIntervalSince(dayStart) / 60)))
            endSlotIndex = min(
                slotsPerDay,
                max(startSlotIndex + 1, Int(ceil(Double(endMinute) / Double(slotMinutes))))
            )
        }

        guard startSlotIndex < endSlotIndex else {
            return nil
        }

        return PlacementInput(
            columnKind: columnKind(for: event.kind),
            startSlotIndex: startSlotIndex,
            endSlotIndex: endSlotIndex,
            events: [
                PlacementEvent(
                    id: event.id,
                    start: eventStart(for: event)
                )
            ]
        )
    }

    private func visibleInterval(
        for event: BabyEvent,
        dayStart: Date,
        dayEnd: Date,
        now: Date
    ) -> (start: Date, end: Date) {
        // The use case works with an exclusive day end. That keeps midnight
        // rollover cases predictable and avoids producing slot indexes beyond
        // the final slot in the day.
        let start = max(dayStart, eventStart(for: event))
        let end = min(dayEnd, eventEnd(for: event, now: now))
        return (start, end)
    }

    private func columnKind(for kind: BabyEventKind) -> TimelineDayGridColumnKind {
        switch kind {
        case .sleep:
            return .sleep
        case .nappy:
            return .nappy
        case .bottleFeed:
            return .bottleFeed
        case .breastFeed:
            return .breastFeed
        }
    }

    private func occupiesSingleSlot(_ event: BabyEvent) -> Bool {
        switch event {
        case .bottleFeed, .nappy:
            true
        case .breastFeed, .sleep:
            false
        }
    }

    private func eventStart(for event: BabyEvent) -> Date {
        switch event {
        case let .breastFeed(feed):
            feed.startedAt
        case let .bottleFeed(feed):
            feed.metadata.occurredAt
        case let .sleep(sleep):
            sleep.startedAt
        case let .nappy(nappy):
            nappy.metadata.occurredAt
        }
    }

    private func eventEnd(
        for event: BabyEvent,
        now: Date
    ) -> Date {
        switch event {
        case let .breastFeed(feed):
            feed.endedAt
        case let .bottleFeed(feed):
            feed.metadata.occurredAt.addingTimeInterval(TimeInterval(slotMinutes * 60))
        case let .sleep(sleep):
            sleep.endedAt ?? now
        case let .nappy(nappy):
            nappy.metadata.occurredAt.addingTimeInterval(TimeInterval(slotMinutes * 60))
        }
    }
}

private struct PlacementInput: Equatable, Sendable {
    let columnKind: TimelineDayGridColumnKind
    var startSlotIndex: Int
    var endSlotIndex: Int

    // A merged placement may represent multiple source events once overlapping
    // items in the same column have been collapsed together.
    var events: [PlacementEvent]

    var eventStart: Date {
        events.first?.start ?? .distantPast
    }
}

private struct PlacementEvent: Equatable, Sendable {
    let id: UUID
    let start: Date
}
