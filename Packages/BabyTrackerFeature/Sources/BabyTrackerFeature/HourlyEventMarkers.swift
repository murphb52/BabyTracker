import BabyTrackerDomain
import Foundation

public struct BottleEventMarker: Equatable, Sendable {
    public let amountMilliliters: Int
    public let milkType: MilkType?
    public let time: String
}

public struct BreastEventMarker: Equatable, Sendable {
    public let side: BreastSide?
    public let durationMinutes: Int
    public let time: String
}

public struct SleepEventMarker: Equatable, Sendable {
    public let durationMinutes: Int
    public let wakeTime: String
}

public struct NappyEventMarker: Equatable, Sendable {
    public let type: NappyType
    public let time: String
}
