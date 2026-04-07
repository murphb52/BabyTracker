import BabyTrackerDomain
import Foundation

public struct EventCardViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String
    public let timestampText: String
    public let actionPayload: EventActionPayload

    public init(
        id: UUID,
        kind: BabyEventKind,
        title: String,
        detailText: String,
        timestampText: String,
        actionPayload: EventActionPayload
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detailText = detailText
        self.timestampText = timestampText
        self.actionPayload = actionPayload
    }

    public init?(
        event: BabyEvent,
        preferredFeedVolumeUnit: FeedVolumeUnit = .milliliters,
        timestampText: String? = nil
    ) {
        switch event {
        case let .breastFeed(feed):
            let durationMinutes = max(
                1,
                Int((feed.endedAt ?? .now).timeIntervalSince(feed.startedAt) / 60)
            )

            id = feed.id
            kind = .breastFeed
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(
                for: event,
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ) ?? ""
            self.timestampText = timestampText ?? feed.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
            if feed.endedAt == nil {
                actionPayload = .endBreastFeed(startedAt: feed.startedAt, side: feed.side)
            } else {
                actionPayload = .editBreastFeed(
                    durationMinutes: durationMinutes,
                    endTime: feed.endedAt ?? .now,
                    side: feed.side,
                    leftDurationSeconds: feed.leftDurationSeconds,
                    rightDurationSeconds: feed.rightDurationSeconds
                )
            }
        case let .bottleFeed(feed):
            id = feed.id
            kind = .bottleFeed
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(
                for: event,
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ) ?? ""
            self.timestampText = timestampText ?? feed.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
            actionPayload = .editBottleFeed(
                amountMilliliters: feed.amountMilliliters,
                occurredAt: feed.metadata.occurredAt,
                milkType: feed.milkType
            )
        case let .sleep(sleep):
            id = sleep.id
            kind = .sleep
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(
                for: event,
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ) ?? ""
            self.timestampText = timestampText ?? sleep.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )

            if let endedAt = sleep.endedAt {
                actionPayload = .editSleep(
                    startedAt: sleep.startedAt,
                    endedAt: endedAt
                )
            } else {
                actionPayload = .endSleep(startedAt: sleep.startedAt)
            }
        case let .nappy(nappy):
            id = nappy.id
            kind = .nappy
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(
                for: event,
                preferredFeedVolumeUnit: preferredFeedVolumeUnit
            ) ?? ""
            self.timestampText = timestampText ?? nappy.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
            actionPayload = .editNappy(
                type: nappy.type,
                occurredAt: nappy.metadata.occurredAt,
                peeVolume: nappy.peeVolume,
                pooVolume: nappy.pooVolume,
                pooColor: nappy.pooColor
            )
        }
    }
}
