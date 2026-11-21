import Foundation

public enum AskMessageKind: Equatable, Sendable {
    case question
    case answer
    /// Informational line from the app, such as a conversation reset.
    case notice
    case error
}
