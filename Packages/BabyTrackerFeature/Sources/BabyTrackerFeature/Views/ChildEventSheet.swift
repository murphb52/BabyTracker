import BabyTrackerDomain
import Foundation

public enum ChildEventSheet: Identifiable {
    case quickLogBreastFeed
    case quickLogBottleFeed(smartSuggestions: [Int])
    case startSleep(suggestions: [(label: String, date: Date)])
    case endSleep(id: UUID, startedAt: Date)
    case logPastSleep(suggestions: [(label: String, date: Date)])
    case quickLogNappy(NappyType)
    case editBreastFeed(
        id: UUID,
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        leftDurationSeconds: Int?,
        rightDurationSeconds: Int?
    )
    case editBottleFeed(
        id: UUID,
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    )
    case editSleep(
        id: UUID,
        startedAt: Date,
        endedAt: Date
    )
    case editNappy(
        id: UUID,
        type: NappyType,
        occurredAt: Date,
        peeVolume: NappyVolume?,
        pooVolume: NappyVolume?,
        pooColor: PooColor?
    )

    public init(id: UUID, actionPayload: EventActionPayload) {
        switch actionPayload {
        case let .editBreastFeed(durationMinutes, endTime, side, leftDurationSeconds, rightDurationSeconds):
            self = .editBreastFeed(
                id: id,
                durationMinutes: durationMinutes,
                endTime: endTime,
                side: side,
                leftDurationSeconds: leftDurationSeconds,
                rightDurationSeconds: rightDurationSeconds
            )
        case let .editBottleFeed(amountMilliliters, occurredAt, milkType):
            self = .editBottleFeed(
                id: id,
                amountMilliliters: amountMilliliters,
                occurredAt: occurredAt,
                milkType: milkType
            )
        case let .editNappy(type, occurredAt, peeVolume, pooVolume, pooColor):
            self = .editNappy(
                id: id,
                type: type,
                occurredAt: occurredAt,
                peeVolume: peeVolume,
                pooVolume: pooVolume,
                pooColor: pooColor
            )
        case let .editSleep(startedAt, endedAt):
            self = .editSleep(
                id: id,
                startedAt: startedAt,
                endedAt: endedAt
            )
        case let .endSleep(startedAt):
            self = .endSleep(id: id, startedAt: startedAt)
        }
    }

    public var id: String {
        switch self {
        case .quickLogBreastFeed:
            "quick-log-breast-feed"
        case .quickLogBottleFeed:
            "quick-log-bottle-feed"
        case .startSleep:
            "start-sleep"
        case let .endSleep(id, _):
            "end-sleep-\(id.uuidString)"
        case .logPastSleep:
            "log-past-sleep"
        case let .quickLogNappy(type):
            "quick-log-nappy-\(type.rawValue)"
        case let .editBreastFeed(id, _, _, _, _, _):
            "edit-breast-feed-\(id.uuidString)"
        case let .editBottleFeed(id, _, _, _):
            "edit-bottle-feed-\(id.uuidString)"
        case let .editSleep(id, _, _):
            "edit-sleep-\(id.uuidString)"
        case let .editNappy(id, _, _, _, _, _):
            "edit-nappy-\(id.uuidString)"
        }
    }
}
