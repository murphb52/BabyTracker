import BabyTrackerDomain
import Foundation

public enum BabyEventPresentation {
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

    static func detailText(
        for event: BabyEvent,
        preferredFeedVolumeUnit: FeedVolumeUnit = .milliliters
    ) -> String? {
        switch event {
        case let .breastFeed(feed):
            breastFeedDetailText(for: feed)
        case let .bottleFeed(feed):
            bottleFeedDetailText(for: feed, preferredFeedVolumeUnit: preferredFeedVolumeUnit)
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

    public static func systemImage(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "figure.seated.side.air.upper"
        case .bottleFeed:
            "waterbottle.fill"
        case .sleep:
            "moon.zzz.fill"
        case .nappy:
            "checklist.checked"
        }
    }

    private static func breastFeedDetailText(
        for feed: BreastFeedEvent
    ) -> String {
        let durationMinutes = max(
            1,
            Int((feed.endedAt ?? .now).timeIntervalSince(feed.startedAt) / 60)
        )

        guard let side = feed.side else {
            return DurationText.short(minutes: durationMinutes, minuteStyle: .word)
        }

        return "\(DurationText.short(minutes: durationMinutes, minuteStyle: .word)) • \(breastSideTitle(for: side))"
    }

    private static func bottleFeedDetailText(
        for feed: BottleFeedEvent,
        preferredFeedVolumeUnit: FeedVolumeUnit
    ) -> String {
        let amountText = FeedVolumeConverter.format(
            amountMilliliters: feed.amountMilliliters,
            in: preferredFeedVolumeUnit
        )

        guard let milkType = feed.milkType else {
            return amountText
        }

        return "\(amountText) • \(milkTypeTitle(for: milkType))"
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
        return DurationText.short(minutes: durationMinutes, minuteStyle: .word)
    }

    private static func nappyDetailText(
        for event: NappyEvent
    ) -> String {
        var parts = [nappyTypeTitle(for: event.type)]

        if let peeVolume = event.peeVolume {
            parts.append("Pee: \(nappyVolumeTitle(for: peeVolume))")
        }

        if let pooVolume = event.pooVolume {
            parts.append("Poo: \(nappyVolumeTitle(for: pooVolume))")
        }

        if let pooColor = event.pooColor {
            parts.append(pooColorTitle(for: pooColor))
        }

        return parts.joined(separator: " • ")
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
            "Pee"
        case .poo:
            "Poo"
        case .mixed:
            "Mixed"
        }
    }

    private static func nappyVolumeTitle(for volume: NappyVolume) -> String {
        switch volume {
        case .light: "Light"
        case .medium: "Medium"
        case .heavy: "Heavy"
        }
    }

    private static func pooColorTitle(for color: PooColor) -> String {
        switch color {
        case .yellow:
            "Yellow"
        case .mustard:
            "Mustard"
        case .brown:
            "Brown"
        case .green:
            "Green"
        case .black:
            "Black"
        case .other:
            "Other"
        }
    }
}
