import BabyTrackerDomain
import Foundation

/// Canned answers for SwiftUI previews of the Ask screen.
@MainActor
final class PreviewQuestionAnswerer: ChildQuestionAnswering {
    var availability: AssistantAvailability { .available }

    func answer(_ question: String, for child: Child) async throws -> AssistantAnswer {
        try await Task.sleep(for: .seconds(1))
        return AssistantAnswer(text: "\(child.name) last fed 2 hours 10 minutes ago: a 120 ml bottle of formula.")
    }

    func resetConversation() {}
}
