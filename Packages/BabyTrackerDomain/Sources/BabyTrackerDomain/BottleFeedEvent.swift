import Foundation

public struct BottleFeedEvent: Equatable, Identifiable, Sendable {
    public var metadata: EventMetadata
    public var amountMilliliters: Int
    public var milkType: MilkType?

    public var id: UUID {
        metadata.id
    }

    public init(
        metadata: EventMetadata,
        amountMilliliters: Int,
        milkType: MilkType? = nil
    ) throws {
        guard amountMilliliters > 0 else {
            throw BabyEventError.invalidBottleAmount
        }

        self.metadata = metadata
        self.amountMilliliters = amountMilliliters
        self.milkType = milkType
    }
}
