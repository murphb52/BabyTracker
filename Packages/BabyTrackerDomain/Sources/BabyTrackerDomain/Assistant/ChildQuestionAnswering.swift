import Foundation

/// Answers natural-language questions about one child's logged events.
///
/// Implementations keep a conversation per child so follow-up questions work.
/// The presentation layer only depends on this protocol, which keeps the
/// language-model framework at the app's edge.
@MainActor
public protocol ChildQuestionAnswering: AnyObject {
    var availability: AssistantAvailability { get }
    func answer(_ question: String, for child: Child) async throws -> AssistantAnswer
    func resetConversation()
}
