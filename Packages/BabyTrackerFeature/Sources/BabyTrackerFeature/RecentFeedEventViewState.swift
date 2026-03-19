import BabyTrackerDomain
import Foundation

public struct RecentFeedEventViewState: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let kind: BabyEventKind
    public let title: String
    public let detailText: String
    public let timestampText: String
    public let editPayload: EditPayload

    public init?(event: BabyEvent) {
        switch event {
        case let .breastFeed(feed):
            id = feed.id
            kind = .breastFeed
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(for: event) ?? ""
            let durationMinutes = max(
                1,
                Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60)
            )

            timestampText = feed.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
            editPayload = .breastFeed(
                durationMinutes: durationMinutes,
                endTime: feed.endedAt,
                side: feed.side
            )
        case let .bottleFeed(feed):
            id = feed.id
            kind = .bottleFeed
            title = BabyEventPresentation.title(for: event)
            detailText = BabyEventPresentation.detailText(for: event) ?? ""

            timestampText = feed.metadata.occurredAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
            editPayload = .bottleFeed(
                amountMilliliters: feed.amountMilliliters,
                occurredAt: feed.metadata.occurredAt,
                milkType: feed.milkType
            )
        case .sleep, .nappy:
            return nil
        }
    }
}

extension RecentFeedEventViewState {
    public enum EditPayload: Equatable, Sendable {
        case breastFeed(durationMinutes: Int, endTime: Date, side: BreastSide?)
        case bottleFeed(amountMilliliters: Int, occurredAt: Date, milkType: MilkType?)
    }
}
