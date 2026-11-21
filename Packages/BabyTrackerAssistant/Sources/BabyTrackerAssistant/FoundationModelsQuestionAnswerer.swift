import BabyTrackerDomain
import Foundation
import FoundationModels

/// Answers questions with Apple's on-device language model.
///
/// It keeps one session per child, so follow-up questions have context. A new
/// session starts when the child changes, on `resetConversation()`, or when
/// the model's small context window fills up.
@MainActor
public final class FoundationModelsQuestionAnswerer: ChildQuestionAnswering {
    private let eventRepository: any EventRepository
    private let calendar: Calendar
    private let now: () -> Date
    private var session: LanguageModelSession?
    private var sessionChildID: UUID?

    public init(
        eventRepository: any EventRepository,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = Date.init
    ) {
        self.eventRepository = eventRepository
        self.calendar = calendar
        self.now = now
    }

    public var availability: AssistantAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            .available
        case .unavailable(.appleIntelligenceNotEnabled):
            .appleIntelligenceDisabled
        case .unavailable(.modelNotReady):
            .modelNotReady
        case .unavailable:
            .deviceNotEligible
        }
    }

    public func answer(_ question: String, for child: Child) async throws -> AssistantAnswer {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuestion.isEmpty else { throw AssistantError.emptyQuestion }
        guard availability.isAvailable else { throw AssistantError.unavailable }

        do {
            let text = try await respond(to: trimmedQuestion, for: child)
            return AssistantAnswer(text: text)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // The on-device context window is small. Start again with only
            // this question rather than failing the conversation.
            resetConversation()
            let text = try await respond(to: trimmedQuestion, for: child)
            return AssistantAnswer(text: text, didResetConversation: true)
        }
    }

    public func resetConversation() {
        session = nil
        sessionChildID = nil
    }

    private func respond(to question: String, for child: Child) async throws -> String {
        do {
            let response = try await currentSession(for: child).respond(to: question)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                throw error
            case .guardrailViolation:
                throw AssistantError.declined
            default:
                throw AssistantError.failed
            }
        }
    }

    private func currentSession(for child: Child) -> LanguageModelSession {
        if let session, sessionChildID == child.id {
            return session
        }

        let dataSource = AssistantDataSource(
            childID: child.id,
            eventRepository: eventRepository,
            calendar: calendar,
            now: now
        )
        let newSession = LanguageModelSession(
            tools: [
                LastEventTool(dataSource: dataSource),
                EventSummaryTool(dataSource: dataSource),
                ComparePeriodsTool(dataSource: dataSource),
                DailyPatternTool(dataSource: dataSource),
            ],
            instructions: AssistantInstructions.make(for: child, now: now(), calendar: calendar)
        )
        session = newSession
        sessionChildID = child.id
        return newSession
    }
}
