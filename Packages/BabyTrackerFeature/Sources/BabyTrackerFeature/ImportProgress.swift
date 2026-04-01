import Foundation

/// Tracks how many events have been saved during a batch import.
public struct ImportProgress: Equatable, Sendable {
    public let completed: Int
    public let total: Int

    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
    }
}
