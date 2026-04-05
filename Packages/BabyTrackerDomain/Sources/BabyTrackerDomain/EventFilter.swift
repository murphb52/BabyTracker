import Foundation

public struct EventFilter: Equatable, Sendable {
    public var eventTypes: Set<BabyEventKind>
    public var nappyTypes: Set<NappyType>
    public var milkTypes: Set<MilkType>
    public var breastSides: Set<BreastSide>
    public var sleepMinDurationMinutes: Int?
    public var sleepMaxDurationMinutes: Int?
    public var occurredOnOrAfter: Date?
    public var occurredOnOrBefore: Date?

    public init(
        eventTypes: Set<BabyEventKind>,
        nappyTypes: Set<NappyType>,
        milkTypes: Set<MilkType>,
        breastSides: Set<BreastSide>,
        sleepMinDurationMinutes: Int?,
        sleepMaxDurationMinutes: Int?,
        occurredOnOrAfter: Date?,
        occurredOnOrBefore: Date?
    ) {
        self.eventTypes = eventTypes
        self.nappyTypes = nappyTypes
        self.milkTypes = milkTypes
        self.breastSides = breastSides
        self.sleepMinDurationMinutes = sleepMinDurationMinutes
        self.sleepMaxDurationMinutes = sleepMaxDurationMinutes
        self.occurredOnOrAfter = occurredOnOrAfter
        self.occurredOnOrBefore = occurredOnOrBefore
    }

    public static let empty = EventFilter(
        eventTypes: [],
        nappyTypes: [],
        milkTypes: [],
        breastSides: [],
        sleepMinDurationMinutes: nil,
        sleepMaxDurationMinutes: nil,
        occurredOnOrAfter: nil,
        occurredOnOrBefore: nil
    )

    public var isEmpty: Bool {
        eventTypes.isEmpty &&
        nappyTypes.isEmpty &&
        milkTypes.isEmpty &&
        breastSides.isEmpty &&
        sleepMinDurationMinutes == nil &&
        sleepMaxDurationMinutes == nil &&
        occurredOnOrAfter == nil &&
        occurredOnOrBefore == nil
    }

    public func matches(_ event: BabyEvent) -> Bool {
        if let occurredOnOrAfter, event.metadata.occurredAt < occurredOnOrAfter {
            return false
        }

        if let occurredOnOrBefore, event.metadata.occurredAt > occurredOnOrBefore {
            return false
        }

        if !eventTypes.isEmpty, !eventTypes.contains(event.kind) {
            return false
        }

        switch event {
        case let .nappy(nappy):
            if !nappyTypes.isEmpty, !nappyTypes.contains(nappy.type) {
                return false
            }

        case let .bottleFeed(bottle):
            if !milkTypes.isEmpty {
                guard let milkType = bottle.milkType, milkTypes.contains(milkType) else {
                    return false
                }
            }

        case let .breastFeed(feed):
            if !breastSides.isEmpty {
                guard let side = feed.side, breastSides.contains(side) else {
                    return false
                }
            }

        case let .sleep(sleep):
            // Ongoing sleeps (nil endedAt) always pass duration checks
            if let endedAt = sleep.endedAt {
                let durationMinutes = Int(endedAt.timeIntervalSince(sleep.startedAt) / 60)
                if let min = sleepMinDurationMinutes, durationMinutes < min {
                    return false
                }
                if let max = sleepMaxDurationMinutes, durationMinutes > max {
                    return false
                }
            }
        }

        return true
    }
}
