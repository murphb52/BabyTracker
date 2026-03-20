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
            intensity: nappyEvent.intensity,
            pooColor: nappyEvent.pooColor
        )
    }
}

extension RecentNappyEventViewState {
    public struct EditPayload: Equatable, Sendable {
        public let type: NappyType
        public let occurredAt: Date
        public let intensity: NappyIntensity?
        public let pooColor: PooColor?

        public init(
            type: NappyType,
            occurredAt: Date,
            intensity: NappyIntensity?,
            pooColor: PooColor?
        ) {
            self.type = type
            self.occurredAt = occurredAt
            self.intensity = intensity
            self.pooColor = pooColor
        }
    }
}
