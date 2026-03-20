import BabyTrackerDomain
import Foundation

public enum TimelineEventActionPayload: Equatable, Sendable {
    case editBreastFeed(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?
    )
    case editBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    )
    case editNappy(
        type: NappyType,
        occurredAt: Date,
        intensity: NappyIntensity?,
        pooColor: PooColor?
    )
    case editSleep(
        startedAt: Date,
        endedAt: Date
    )
    case endSleep(startedAt: Date)
}
