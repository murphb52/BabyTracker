import CloudKit
import Foundation

public struct CloudKitPendingInvite: Equatable, Sendable, Identifiable {
    public let childID: UUID
    public let participantID: String
    public let displayName: String
    public let acceptanceStatus: CKShare.ParticipantAcceptanceStatus

    public var id: String {
        participantID
    }

    public init(
        childID: UUID,
        participantID: String,
        displayName: String,
        acceptanceStatus: CKShare.ParticipantAcceptanceStatus
    ) {
        self.childID = childID
        self.participantID = participantID
        self.displayName = displayName
        self.acceptanceStatus = acceptanceStatus
    }
}
