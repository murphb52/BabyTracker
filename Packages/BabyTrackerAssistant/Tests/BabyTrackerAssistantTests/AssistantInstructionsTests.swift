@testable import BabyTrackerAssistant
import BabyTrackerDomain
import Foundation
import Testing

struct AssistantInstructionsTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private var now: Date {
        calendar.date(from: DateComponents(year: 2024, month: 6, day: 15, hour: 14))!
    }

    @Test
    func includesNameAgeInMonthsAndCurrentTime() throws {
        let birthDate = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        let child = try Child(name: "Ada", birthDate: birthDate, createdBy: UUID())

        let text = AssistantInstructions.make(for: child, now: now, calendar: calendar)

        #expect(text.contains("Ada is 4 months old."))
        #expect(text.contains("14:00 on Saturday 15 June 2024"))
    }

    @Test
    func usesWeeksForNewborns() throws {
        let birthDate = calendar.date(byAdding: .day, value: -15, to: now)!
        let child = try Child(name: "Ada", birthDate: birthDate, createdBy: UUID())

        #expect(AssistantInstructions.make(for: child, now: now, calendar: calendar).contains("Ada is 2 weeks old."))
    }

    @Test
    func handlesMissingBirthDate() throws {
        let child = try Child(name: "Ada", createdBy: UUID())
        #expect(AssistantInstructions.make(for: child, now: now, calendar: calendar).contains("date of birth has not been recorded"))
    }

    @Test
    func keepsMedicalSafetyRules() throws {
        let child = try Child(name: "Ada", createdBy: UUID())
        let text = AssistantInstructions.make(for: child, now: now, calendar: calendar)

        #expect(text.contains("Never diagnose"))
        #expect(text.contains("health visitor"))
        #expect(text.contains("emergency services"))
    }
}
