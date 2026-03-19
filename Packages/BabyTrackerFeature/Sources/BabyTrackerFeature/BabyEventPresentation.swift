import BabyTrackerDomain
import Foundation

enum BabyEventPresentation {
    static func title(for event: BabyEvent) -> String {
        title(for: event.kind)
    }

    static func title(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "Breast Feed"
        case .bottleFeed:
            "Bottle Feed"
        case .sleep:
            "Sleep"
        case .nappy:
            "Nappy"
        }
    }

    static func detailText(for event: BabyEvent) -> String? {
        switch event {
        case let .breastFeed(feed):
            breastFeedDetailText(for: feed)
        case let .bottleFeed(feed):
            bottleFeedDetailText(for: feed)
        case let .sleep(event):
            sleepDetailText(for: event)
        case let .nappy(event):
            nappyDetailText(for: event)
        }
    }

    static func milkTypeTitle(for milkType: MilkType) -> String {
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

    static func systemImage(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "heart.text.square"
        case .bottleFeed:
            "drop.circle"
        case .sleep:
            "bed.double"
        case .nappy:
            "checklist"
        }
    }

    private static func breastFeedDetailText(
        for feed: BreastFeedEvent
    ) -> String {
        let durationMinutes = max(
            1,
            Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60)
        )

        guard let side = feed.side else {
            return "\(durationMinutes) min"
        }

        return "\(durationMinutes) min • \(breastSideTitle(for: side))"
    }

    private static func bottleFeedDetailText(
        for feed: BottleFeedEvent
    ) -> String {
        guard let milkType = feed.milkType else {
            return "\(feed.amountMilliliters) mL"
        }

        return "\(feed.amountMilliliters) mL • \(milkTypeTitle(for: milkType))"
    }

    private static func sleepDetailText(
        for event: SleepEvent
    ) -> String {
        guard let endedAt = event.endedAt else {
            return "In progress"
        }

        let durationMinutes = max(
            1,
            Int(endedAt.timeIntervalSince(event.startedAt) / 60)
        )
        return "\(durationMinutes) min"
    }

    private static func nappyDetailText(
        for event: NappyEvent
    ) -> String {
        let base = nappyTypeTitle(for: event.type)

        guard let intensity = event.intensity else {
            return base
        }

        return "\(base) • \(nappyIntensityTitle(for: intensity))"
    }

    private static func breastSideTitle(for side: BreastSide) -> String {
        switch side {
        case .left:
            "Left"
        case .right:
            "Right"
        case .both:
            "Both"
        }
    }

    private static func nappyTypeTitle(for type: NappyType) -> String {
        switch type {
        case .dry:
            "Dry"
        case .wee:
            "Wee"
        case .poo:
            "Poo"
        case .mixed:
            "Mixed"
        }
    }

    private static func nappyIntensityTitle(
        for intensity: NappyIntensity
    ) -> String {
        switch intensity {
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        }
    }
}
