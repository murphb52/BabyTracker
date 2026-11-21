import BabyTrackerDomain
import Foundation

/// Turns domain query results into short, plain sentences for the model.
///
/// Tool output takes up the model's small context window, so it is kept
/// compact and already contains every number the answer needs. That way
/// the model never has to do arithmetic.
enum AssistantToolText {
    static func lastEvent(_ event: BabyEvent?, category: EventSummaryCategory, now: Date, calendar: Calendar) -> String {
        guard let event else {
            return "No \(category.spokenName) have been logged yet."
        }

        let time = timestamp(event.metadata.occurredAt, calendar: calendar)
        let elapsedMinutes = Int(now.timeIntervalSince(event.metadata.occurredAt) / 60)
        let elapsed = DurationText.spoken(minutes: elapsedMinutes)

        if case let .sleep(sleep) = event, sleep.endedAt == nil {
            let asleepMinutes = Int(now.timeIntervalSince(sleep.startedAt) / 60)
            return "Sleep in progress: started at \(time), asleep for \(DurationText.spoken(minutes: asleepMinutes)) so far."
        }

        return "\(describe(event)). Logged at \(time), which was \(elapsed) ago."
    }

    static func summary(_ summary: EventRangeSummary) -> String {
        let name = summary.category.spokenName
        guard summary.eventCount > 0 else {
            return "No \(name) were logged \(summary.period.displayName)."
        }

        var lines = [
            "\(name.capitalizedFirstLetter) \(summary.period.displayName): \(summary.eventCount) in total, " +
                "an average of \(oneDecimal(summary.averageEventsPerDay)) per day.",
        ]
        lines.append(contentsOf: categoryDetailLines(summary))
        if summary.period.includesToday {
            lines.append("Today is not over yet, so this period is still incomplete.")
        }
        return lines.joined(separator: "\n")
    }

    static func comparison(current: EventRangeSummary, earlier: EventRangeSummary) -> String {
        var lines = [
            "Current period: " + summary(current),
            "Earlier period: " + summary(earlier),
            "Change in daily average count: " + signedChange(current.averageEventsPerDay - earlier.averageEventsPerDay) + " per day.",
        ]

        switch current.category {
        case .sleep:
            let change = Int((current.averageSleepMinutesPerDay - earlier.averageSleepMinutesPerDay).rounded())
            let direction = change >= 0 ? "more" : "less"
            lines.append("Daily sleep changed by \(DurationText.spoken(minutes: abs(change))) \(direction) per day.")
        case .feeds:
            let change = current.averageBottleMillilitersPerDay - earlier.averageBottleMillilitersPerDay
            lines.append("Daily bottle volume changed by \(signedChange(change)) ml per day.")
        case .nappies, .food, .medication, .bath:
            break
        }

        return lines.joined(separator: "\n")
    }

    static func pattern(_ pattern: DailyPattern) -> String {
        let name = pattern.category.spokenName
        guard pattern.eventCount > 0 else {
            return "No \(name) were logged \(pattern.period.displayName), so there is no pattern yet."
        }

        let busiest = pattern.busiestHours(limit: 3).map { hour in
            "\(hourRangeLabel(hour)) (\(pattern.countsByHour[hour]) times)"
        }
        let startVerb = pattern.category == .sleep ? "started" : "happened"
        return "Over \(pattern.period.displayName), \(pattern.eventCount) \(name) were logged. " +
            "They most often \(startVerb) between: \(busiest.joined(separator: ", "))."
    }

    // MARK: - Category details

    private static func categoryDetailLines(_ summary: EventRangeSummary) -> [String] {
        switch summary.category {
        case .feeds:
            return [
                "Bottle feeds: \(summary.bottleFeedCount), totalling \(summary.bottleTotalMilliliters) ml " +
                    "(\(Int(summary.averageBottleMillilitersPerDay.rounded())) ml per day on average).",
                "Breast feeds: \(summary.breastFeedCount), totalling \(DurationText.spoken(minutes: summary.breastFeedTotalMinutes)).",
            ]
        case .sleep:
            var lines = [
                "Completed sleeps: \(summary.completedSleepCount), totalling \(DurationText.spoken(minutes: summary.totalSleepMinutes)) " +
                    "(\(DurationText.spoken(minutes: Int(summary.averageSleepMinutesPerDay.rounded()))) per day on average).",
            ]
            if let longest = summary.longestSleepMinutes {
                lines.append("Longest sleep: \(DurationText.spoken(minutes: longest)).")
            }
            return lines
        case .nappies:
            let counts = summary.nappyCountsByType
            return [
                "Wet: \(counts[.wee, default: 0]), dirty: \(counts[.poo, default: 0]), " +
                    "wet and dirty: \(counts[.mixed, default: 0]), dry: \(counts[.dry, default: 0]).",
            ]
        case .food, .medication:
            let items = summary.itemCountsByName
                .sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
                .map { "\($0.key) (\($0.value)x)" }
            return ["Items: \(items.joined(separator: ", "))."]
        case .bath:
            return []
        }
    }

    private static func describe(_ event: BabyEvent) -> String {
        switch event {
        case let .bottleFeed(feed):
            let milk = feed.milkType.map { " of \($0.spokenName)" } ?? ""
            return "Bottle feed: \(feed.amountMilliliters) ml\(milk)"
        case let .breastFeed(feed):
            let minutes = max(1, Int(feed.endedAt.timeIntervalSince(feed.startedAt) / 60))
            let side = feed.side.map { ", \($0.spokenName)" } ?? ""
            return "Breast feed: \(DurationText.spoken(minutes: minutes))\(side)"
        case let .sleep(sleep):
            let minutes = sleep.endedAt.map { max(1, Int($0.timeIntervalSince(sleep.startedAt) / 60)) } ?? 0
            return "Sleep: \(DurationText.spoken(minutes: minutes)), woke up"
        case let .nappy(nappy):
            return "Nappy: \(nappy.type.spokenName)"
        case let .food(food):
            return "Food: \(food.foodName), \(food.displayAmount)"
        case let .medication(medication):
            return "Medication: \(medication.medicineName), \(medication.formattedAmount) \(medication.displayUnit)"
        case let .bath(bath):
            var extras: [String] = []
            if bath.usedShampoo { extras.append("shampoo") }
            if bath.usedSoap { extras.append("soap") }
            return extras.isEmpty ? "Bath" : "Bath with \(extras.joined(separator: " and "))"
        }
    }

    // MARK: - Formatting

    private static func timestamp(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "HH:mm 'on' EEEE d MMMM"
        return formatter.string(from: date)
    }

    static func hourRangeLabel(_ hour: Int) -> String {
        "\(hourLabel(hour)) and \(hourLabel((hour + 1) % 24))"
    }

    private static func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: "12am"
        case 12: "12pm"
        case 1..<12: "\(hour)am"
        default: "\(hour - 12)pm"
        }
    }

    private static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func signedChange(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded > 0 ? "+\(oneDecimal(rounded))" : oneDecimal(rounded)
    }
}
