import Foundation

public enum AssistantError: Error, Equatable, Sendable {
    case unavailable
    case emptyQuestion
    /// The model's safety guardrails declined to answer.
    case declined
    case failed
}
