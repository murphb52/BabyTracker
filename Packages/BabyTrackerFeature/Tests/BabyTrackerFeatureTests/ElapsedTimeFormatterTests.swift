@testable import BabyTrackerFeature
import Foundation
import Testing

struct ElapsedTimeFormatterTests {
    @Test func justNow_whenUnderOneMinute() {
        let date = Date().addingTimeInterval(-30)
        #expect(ElapsedTimeFormatter.string(from: date) == "just now")
    }

    @Test func justNow_whenExactlyNow() {
        #expect(ElapsedTimeFormatter.string(from: Date()) == "just now")
    }

    @Test func minutesOnly_whenUnderOneHour() {
        let date = Date().addingTimeInterval(-45 * 60)
        #expect(ElapsedTimeFormatter.string(from: date) == "45 mins ago")
    }

    @Test func singularMinute() {
        let date = Date().addingTimeInterval(-60)
        #expect(ElapsedTimeFormatter.string(from: date) == "1 min ago")
    }

    @Test func hoursAndMinutes() {
        let date = Date().addingTimeInterval(-(90 * 60))
        #expect(ElapsedTimeFormatter.string(from: date) == "1 hr 30 mins ago")
    }

    @Test func hoursOnly_whenExactHours() {
        let date = Date().addingTimeInterval(-(2 * 60 * 60))
        #expect(ElapsedTimeFormatter.string(from: date) == "2 hrs ago")
    }

    @Test func singularHour_withMinutes() {
        let date = Date().addingTimeInterval(-(61 * 60))
        #expect(ElapsedTimeFormatter.string(from: date) == "1 hr 1 min ago")
    }
}
