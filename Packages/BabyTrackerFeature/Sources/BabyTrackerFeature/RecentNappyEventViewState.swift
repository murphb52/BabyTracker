import BabyTrackerDomain
import Foundation

public struct RecentNappyEventViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let detailText: String
    public let timestampText: String
    public let editPayload: EditPayload

    public init?(event: BabyEvent) {
        guard case let .nappy(nappyEvent) = event else {
            return nil
        }

        id = nappyEvent.id
        title = BabyEventPresentation.title(for: event)
        detailText = BabyEventPresentation.detailText(for: event) ?? ""
        timestampText = nappyEvent.metadata.occurredAt.formatted(
            date: .abbreviated,
            time: .shortened
        )
        editPayload = EditPayload(
            type: nappyEvent.type,
            occurredAt: nappyEvent.metadata.occurredAt,
            peeVolume: nappyEvent.peeVolume,
            pooVolume: nappyEvent.pooVolume,
            pooColor: nappyEvent.pooColor
        )
    }
}

extension RecentNappyEventViewState {
    public struct EditPayload: Equatable, Sendable {
        public let type: NappyType
        public let occurredAt: Date
        public let peeVolume: NappyVolume?
        public let pooVolume: NappyVolume?
        public let pooColor: PooColor?

        public init(
            type: NappyType,
            occurredAt: Date,
            peeVolume: NappyVolume?,
            pooVolume: NappyVolume?,
            pooColor: PooColor?
        ) {
            self.type = type
            self.occurredAt = occurredAt
            self.peeVolume = peeVolume
            self.pooVolume = pooVolume
            self.pooColor = pooColor
        }
    }
}
