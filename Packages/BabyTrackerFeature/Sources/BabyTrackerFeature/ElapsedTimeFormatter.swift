import Foundation

enum ElapsedTimeFormatter {
    static func string(from date: Date, relativeTo referenceDate: Date = Date()) -> String {
        let interval = referenceDate.timeIntervalSince(date)
        guard interval >= 60 else { return "just now" }

        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours == 0 {
            return "\(totalMinutes) \(totalMinutes == 1 ? "min" : "mins") ago"
        } else if minutes == 0 {
            return "\(hours) \(hours == 1 ? "hr" : "hrs") ago"
        } else {
            return "\(hours) \(hours == 1 ? "hr" : "hrs") \(minutes) \(minutes == 1 ? "min" : "mins") ago"
        }
    }
}
