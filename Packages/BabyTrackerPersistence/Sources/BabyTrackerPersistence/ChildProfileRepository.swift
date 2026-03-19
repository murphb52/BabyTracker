import BabyTrackerDomain
import Foundation

public protocol ChildProfileRepository: Sendable {
    func fetchChildren() async throws -> [Child]
    func saveChild(_ child: Child) async throws
}
