import Foundation

public enum DurationText {
    public enum MinuteStyle: Sendable {
        case letter
        case word
    }

    public static func short(
        minutes: Int,
        minuteStyle: MinuteStyle = .letter
    ) -> String {
        let clampedMinutes = max(0, minutes)
        let hours = clampedMinutes / 60
        let remainingMinutes = clampedMinutes % 60

        if hours == 0 {
            return minuteStyle == .word ? "\(remainingMinutes) min" : "\(remainingMinutes)m"
        }

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }

    public static func spoken(minutes: Int) -> String {
        let clampedMinutes = max(0, minutes)
        let hours = clampedMinutes / 60
        let remainingMinutes = clampedMinutes % 60

        if hours == 0 {
            return minutePhrase(remainingMinutes)
        }

        if remainingMinutes == 0 {
            return hourPhrase(hours)
        }

        return "\(hourPhrase(hours)) \(minutePhrase(remainingMinutes))"
    }

    private static func hourPhrase(_ hours: Int) -> String {
        hours == 1 ? "1 hour" : "\(hours) hours"
    }

    private static func minutePhrase(_ minutes: Int) -> String {
        minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }
}
