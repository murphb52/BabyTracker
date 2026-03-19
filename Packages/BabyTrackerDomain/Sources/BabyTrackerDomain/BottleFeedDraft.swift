import Foundation

public struct BottleFeedDraft: Equatable, Sendable {
    public var amountMilliliters: Int
    public var milkType: MilkType?

    public init(amountMilliliters: Int, milkType: MilkType? = nil) {
        self.amountMilliliters = amountMilliliters
        self.milkType = milkType
    }
}
