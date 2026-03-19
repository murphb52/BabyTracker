import Foundation

public enum MembershipRole: String, CaseIterable, Codable, Sendable {
    case owner
    case caregiver

    public var canManageCaregivers: Bool {
        self == .owner
    }
}
