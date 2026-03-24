import BabyTrackerDomain
import Foundation

public enum ChildEventSheet: Identifiable {
    case quickLogBreastFeed
    case quickLogBottleFeed
    case startSleep
    case endSleep(id: UUID, startedAt: Date)
    case quickLogNappy(NappyType)
    case editBreastFeed(
        id: UUID,
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?
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
        intensity: NappyIntensity?,
        pooColor: PooColor?
    )

    public init(id: UUID, actionPayload: EventActionPayload) {
        switch actionPayload {
        case let .editBreastFeed(durationMinutes, endTime, side):
            self = .editBreastFeed(
                id: id,
                durationMinutes: durationMinutes,
                endTime: endTime,
                side: side
            )
        case let .editBottleFeed(amountMilliliters, occurredAt, milkType):
            self = .editBottleFeed(
                id: id,
                amountMilliliters: amountMilliliters,
                occurredAt: occurredAt,
                milkType: milkType
            )
        case let .editNappy(type, occurredAt, intensity, pooColor):
            self = .editNappy(
                id: id,
                type: type,
                occurredAt: occurredAt,
                intensity: intensity,
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
        case let .quickLogNappy(type):
            "quick-log-nappy-\(type.rawValue)"
        case let .editBreastFeed(id, _, _, _):
            "edit-breast-feed-\(id.uuidString)"
        case let .editBottleFeed(id, _, _, _):
            "edit-bottle-feed-\(id.uuidString)"
        case let .editSleep(id, _, _):
            "edit-sleep-\(id.uuidString)"
        case let .editNappy(id, _, _, _, _):
            "edit-nappy-\(id.uuidString)"
        }
    }
}
