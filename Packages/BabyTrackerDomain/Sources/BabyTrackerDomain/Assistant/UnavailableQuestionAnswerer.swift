import Foundation

/// Used where no on-device model exists (previews, tests, older builds).
/// Reporting `.deviceNotEligible` keeps the Ask tab hidden.
@MainActor
public final class UnavailableQuestionAnswerer: ChildQuestionAnswering {
    public init() {}

    public var availability: AssistantAvailability {
        .deviceNotEligible
    }

    public func answer(_ question: String, for child: Child) async throws -> AssistantAnswer {
        throw AssistantError.unavailable
    }

    public func resetConversation() {}
}
