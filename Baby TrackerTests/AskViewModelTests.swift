import BabyTrackerDomain
import BabyTrackerFeature
import Foundation
import Testing

@MainActor
struct AskViewModelTests {
    private let child = try! Child(name: "Ada", createdBy: UUID())

    @Test
    func sendingDraftAppendsQuestionThenAnswer() async {
        let answerer = FakeQuestionAnswerer(result: .success(AssistantAnswer(text: "Ada last fed 2 hours ago.")))
        let viewModel = AskViewModel(answerer: answerer)
        viewModel.draftQuestion = "  When did Ada last feed?  "

        await viewModel.sendDraft(for: child)

        #expect(answerer.receivedQuestions == ["When did Ada last feed?"])
        #expect(viewModel.messages.map(\.kind) == [.question, .answer])
        #expect(viewModel.messages.last?.text == "Ada last fed 2 hours ago.")
        #expect(viewModel.draftQuestion.isEmpty)
        #expect(!viewModel.isAnswering)
    }

    @Test
    func blankDraftCannotBeSent() async {
        let answerer = FakeQuestionAnswerer(result: .success(AssistantAnswer(text: "unused")))
        let viewModel = AskViewModel(answerer: answerer)
        viewModel.draftQuestion = "   "

        #expect(!viewModel.canSend)
        await viewModel.sendDraft(for: child)

        #expect(answerer.receivedQuestions.isEmpty)
        #expect(viewModel.messages.isEmpty)
    }

    @Test
    func conversationResetAddsNoticeBeforeAnswer() async {
        let answerer = FakeQuestionAnswerer(result: .success(AssistantAnswer(text: "Fresh answer", didResetConversation: true)))
        let viewModel = AskViewModel(answerer: answerer)

        await viewModel.ask("How many nappies today?", for: child)

        #expect(viewModel.messages.map(\.kind) == [.question, .notice, .answer])
    }

    @Test
    func declinedQuestionShowsMedicalSignpost() async {
        let answerer = FakeQuestionAnswerer(result: .failure(AssistantError.declined))
        let viewModel = AskViewModel(answerer: answerer)

        await viewModel.ask("Something risky", for: child)

        #expect(viewModel.messages.last?.kind == .error)
        #expect(viewModel.messages.last?.text.contains("health visitor") == true)
    }

    @Test
    func startingNewConversationClearsMessagesAndResetsAnswerer() async {
        let answerer = FakeQuestionAnswerer(result: .success(AssistantAnswer(text: "Answer")))
        let viewModel = AskViewModel(answerer: answerer)
        await viewModel.ask("Question", for: child)

        viewModel.startNewConversation()

        #expect(viewModel.messages.isEmpty)
        #expect(answerer.resetCount == 1)
    }
}

@MainActor
private final class FakeQuestionAnswerer: ChildQuestionAnswering {
    private let result: Result<AssistantAnswer, AssistantError>
    private(set) var receivedQuestions: [String] = []
    private(set) var resetCount = 0

    init(result: Result<AssistantAnswer, AssistantError>) {
        self.result = result
    }

    var availability: AssistantAvailability { .available }

    func answer(_ question: String, for child: Child) async throws -> AssistantAnswer {
        receivedQuestions.append(question)
        return try result.get()
    }

    func resetConversation() {
        resetCount += 1
    }
}
