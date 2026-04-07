import BabyTrackerDomain
import Testing

struct DurationTextTests {
    @Test
    func shortFormatterSwitchesToHoursAtSixtyMinutes() {
        #expect(DurationText.short(minutes: 59, minuteStyle: .word) == "59 min")
        #expect(DurationText.short(minutes: 60, minuteStyle: .word) == "1h")
        #expect(DurationText.short(minutes: 75, minuteStyle: .word) == "1h 15m")
    }

    @Test
    func spokenFormatterUsesHourAndMinuteWords() {
        #expect(DurationText.spoken(minutes: 1) == "1 minute")
        #expect(DurationText.spoken(minutes: 60) == "1 hour")
        #expect(DurationText.spoken(minutes: 125) == "2 hours 5 minutes")
    }
}
