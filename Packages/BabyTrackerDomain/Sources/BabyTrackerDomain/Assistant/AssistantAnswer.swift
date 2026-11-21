import Foundation

/// A reply from the assistant to a single question.
public struct AssistantAnswer: Equatable, Sendable {
    public let text: String
    /// True when the conversation had to be restarted before this answer
    /// (for example because the model's context window filled up).
    public let didResetConversation: Bool

    public init(text: String, didResetConversation: Bool = false) {
        self.text = text
        self.didResetConversation = didResetConversation
    }
}
