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
            title = "Breast Feed"

            let durationMinutes = max(
                1,
                Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60)
            )
            let sideText: String? = switch feed.side {
            case .left?:
                "Left"
            case .right?:
                "Right"
            case .both?:
                "Both"
            case nil:
                nil
            }

            if let sideText {
                detailText = "\(durationMinutes) min • \(sideText)"
            } else {
                detailText = "\(durationMinutes) min"
            }

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
            title = "Bottle Feed"

            if let milkType = feed.milkType {
                detailText = "\(feed.amountMilliliters) mL • \(Self.milkTypeTitle(for: milkType))"
            } else {
                detailText = "\(feed.amountMilliliters) mL"
            }

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

    private static func milkTypeTitle(for milkType: MilkType) -> String {
        switch milkType {
        case .breastMilk:
            "Breast Milk"
        case .formula:
            "Formula"
        case .mixed:
            "Mixed"
        case .other:
            "Other"
        }
    }
}

extension RecentFeedEventViewState {
    public enum EditPayload: Equatable, Sendable {
        case breastFeed(durationMinutes: Int, endTime: Date, side: BreastSide?)
        case bottleFeed(amountMilliliters: Int, occurredAt: Date, milkType: MilkType?)
    }
}
