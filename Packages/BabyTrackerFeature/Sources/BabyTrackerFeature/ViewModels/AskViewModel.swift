import BabyTrackerDomain
import Foundation
import Observation

/// State for the Ask tab: the in-memory conversation and the draft question.
/// It only knows the `ChildQuestionAnswering` abstraction, never the model.
@MainActor
@Observable
public final class AskViewModel {
    public private(set) var messages: [AskMessage]
    public private(set) var isAnswering: Bool
    public var draftQuestion: String = ""

    private let answerer: any ChildQuestionAnswering

    public init(
        answerer: any ChildQuestionAnswering,
        messages: [AskMessage] = [],
        isAnswering: Bool = false
    ) {
        self.answerer = answerer
        self.messages = messages
        self.isAnswering = isAnswering
    }

    public var canSend: Bool {
        !isAnswering && !trimmed(draftQuestion).isEmpty
    }

    public func sendDraft(for child: Child) async {
        guard canSend else { return }
        let question = draftQuestion
        draftQuestion = ""
        await ask(question, for: child)
    }

    public func ask(_ question: String, for child: Child) async {
        let question = trimmed(question)
        guard !question.isEmpty, !isAnswering else { return }

        messages.append(AskMessage(kind: .question, text: question))
        isAnswering = true
        defer { isAnswering = false }

        do {
            let answer = try await answerer.answer(question, for: child)
            if answer.didResetConversation {
                messages.append(AskMessage(kind: .notice, text: Self.conversationResetNotice))
            }
            messages.append(AskMessage(kind: .answer, text: answer.text))
        } catch {
            messages.append(AskMessage(kind: .error, text: Self.errorText(for: error)))
        }
    }

    /// Clears the conversation. Call this when the selected child changes,
    /// so one child's context never leaks into another's answers.
    public func startNewConversation() {
        answerer.resetConversation()
        messages = []
        draftQuestion = ""
    }

    static let conversationResetNotice = "That conversation got long, so I started a fresh one."

    static func errorText(for error: Error) -> String {
        switch error as? AssistantError {
        case .declined:
            "I can't help with that one. For anything medical, please check with your GP or health visitor."
        case .unavailable:
            "Apple Intelligence isn't available right now. Check it's turned on in Settings."
        case .emptyQuestion, .failed, nil:
            "Something went wrong answering that. Please try again."
        }
    }

    private func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
