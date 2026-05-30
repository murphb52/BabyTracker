import BabyTrackerDomain
import Foundation

public enum EventActionPayload: Equatable, Sendable {
    case editBath(
        occurredAt: Date,
        usedShampoo: Bool,
        usedSoap: Bool
    )
    case editBreastFeed(
        durationMinutes: Int,
        endTime: Date,
        side: BreastSide?,
        leftDurationSeconds: Int?,
        rightDurationSeconds: Int?
    )
    case editBottleFeed(
        amountMilliliters: Int,
        occurredAt: Date,
        milkType: MilkType?
    )
    case editNappy(
        type: NappyType,
        occurredAt: Date,
        peeVolume: NappyVolume?,
        pooVolume: NappyVolume?,
        pooColor: PooColor?
    )
    case editSleep(
        startedAt: Date,
        endedAt: Date
    )
    case editMedication(
        occurredAt: Date,
        medicineName: String,
        amount: Double,
        unit: MedicationUnit,
        customUnitLabel: String?
    )
    case endSleep(startedAt: Date)
}
