import BabyTrackerDomain
import Foundation

/// Starter questions for the empty Ask screen. They are chosen from the
/// kinds of events the child actually has, so every chip can be answered.
public enum AskSuggestedQuestions {
    static let limit = 6

    public static func make(childName: String, loggedKinds: Set<BabyEventKind>) -> [String] {
        var questions: [String] = []

        if !loggedKinds.isDisjoint(with: [.breastFeed, .bottleFeed]) {
            questions.append("When did \(childName) last feed?")
        }
        if loggedKinds.contains(.sleep) {
            questions.append("Is \(childName) sleeping more this week than last week?")
            questions.append("When does \(childName) usually nap?")
        }
        if loggedKinds.contains(.bottleFeed) {
            questions.append("How much milk has \(childName) had today?")
        }
        if loggedKinds.contains(.nappy) {
            questions.append("How many wet nappies today?")
        }
        if loggedKinds.contains(.food) {
            questions.append("What foods has \(childName) had this week?")
        }
        if loggedKinds.contains(.medication) {
            questions.append("When was \(childName)'s last medicine?")
        }

        if questions.isEmpty {
            questions = [
                "When did \(childName) last feed?",
                "How much did \(childName) sleep yesterday?",
            ]
        }

        return Array(questions.prefix(limit))
    }
}
