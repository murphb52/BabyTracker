import Foundation

public enum MembershipStatus: String, CaseIterable, Codable, Sendable {
    case invited
    case active
    case removed

    public var hasSharedDataAccess: Bool {
        self == .active
    }
}
