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
        let normalizedDay = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: normalizedDay) ?? normalizedDay
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

            if placement.startSlotIndex <= lastPlacement.endSlotIndex {
                var combined = lastPlacement
                combined.startSlotIndex = min(lastPlacement.startSlotIndex, placement.startSlotIndex)
                combined.endSlotIndex = max(lastPlacement.endSlotIndex, placement.endSlotIndex)
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
        let interval = visibleInterval(for: event, dayStart: dayStart, dayEnd: dayEnd, now: now)

        guard interval.end > interval.start else {
            return nil
        }

        let slotsPerDay = (24 * 60) / slotMinutes
        let startMinute = max(0, Int(interval.start.timeIntervalSince(dayStart) / 60))
        let startSlotIndex = min(slotsPerDay, max(0, startMinute / slotMinutes))
        let endSlotIndex: Int

        if occupiesSingleSlot(event) {
            endSlotIndex = min(slotsPerDay, startSlotIndex + 1)
        } else {
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
    var events: [PlacementEvent]

    var eventStart: Date {
        events.first?.start ?? .distantPast
    }
}

private struct PlacementEvent: Equatable, Sendable {
    let id: UUID
    let start: Date
}
