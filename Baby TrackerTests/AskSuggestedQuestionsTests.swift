import BabyTrackerDomain
import BabyTrackerFeature
import Testing

struct AskSuggestedQuestionsTests {
    @Test
    func onlySuggestsQuestionsForLoggedKinds() {
        let questions = AskSuggestedQuestions.make(childName: "Ada", loggedKinds: [.nappy])
        #expect(questions == ["How many wet nappies today?"])
    }

    @Test
    func sleepAddsTrendAndPatternQuestions() {
        let questions = AskSuggestedQuestions.make(childName: "Ada", loggedKinds: [.sleep])
        #expect(questions.contains("Is Ada sleeping more this week than last week?"))
        #expect(questions.contains("When does Ada usually nap?"))
    }

    @Test
    func fallsBackToGeneralQuestionsWithNoData() {
        let questions = AskSuggestedQuestions.make(childName: "Ada", loggedKinds: [])
        #expect(questions.count == 2)
    }

    @Test
    func capsTheNumberOfSuggestions() {
        let questions = AskSuggestedQuestions.make(childName: "Ada", loggedKinds: Set(BabyEventKind.allCases))
        #expect(questions.count == 6)
    }
}
