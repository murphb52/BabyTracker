import BabyTrackerDomain
import SwiftUI

/// The Ask tab: an in-memory chat about the current child.
public struct AskView: View {
    @Bindable var viewModel: AskViewModel
    let child: Child
    let suggestedQuestions: [String]

    private let thinkingIndicatorID = "ask-thinking"

    public init(viewModel: AskViewModel, child: Child, suggestedQuestions: [String]) {
        self.viewModel = viewModel
        self.child = child
        self.suggestedQuestions = suggestedQuestions
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            AskSuggestedQuestionsView(
                                childName: child.name,
                                questions: suggestedQuestions,
                                select: ask
                            )
                        }

                        ForEach(viewModel.messages) { message in
                            AskMessageBubbleView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isAnswering {
                            ProgressView("Thinking…")
                                .id(thinkingIndicatorID)
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isAnswering) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            AskDisclaimerFooterView()
                .padding(.top, 4)

            AskInputBarView(
                childName: child.name,
                draft: $viewModel.draftQuestion,
                canSend: viewModel.canSend,
                send: sendDraft
            )
        }
    }

    private func ask(_ question: String) {
        Task { await viewModel.ask(question, for: child) }
    }

    private func sendDraft() {
        Task { await viewModel.sendDraft(for: child) }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isAnswering {
                proxy.scrollTo(thinkingIndicatorID, anchor: .bottom)
            } else if let lastID = viewModel.messages.last?.id {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

@MainActor
private enum AskViewPreviewData {
    static let child = try! Child(name: "Ada", createdBy: UUID())
    static let questions = AskSuggestedQuestions.make(childName: "Ada", loggedKinds: Set(BabyEventKind.allCases))
}

#Preview("Empty with suggestions") {
    AskView(
        viewModel: AskViewModel(answerer: PreviewQuestionAnswerer()),
        child: AskViewPreviewData.child,
        suggestedQuestions: AskViewPreviewData.questions
    )
}

#Preview("Conversation") {
    AskView(
        viewModel: AskViewModel(
            answerer: PreviewQuestionAnswerer(),
            messages: [
                AskMessage(kind: .question, text: "Is Ada sleeping more this week than last week?"),
                AskMessage(kind: .answer, text: "Yes. Ada has slept about 40 minutes more per day over the last 7 days than the week before."),
                AskMessage(kind: .question, text: "When does she usually nap?"),
                AskMessage(kind: .answer, text: "Ada's naps most often start between 1pm and 2pm, with another common one between 9am and 10am."),
            ]
        ),
        child: AskViewPreviewData.child,
        suggestedQuestions: AskViewPreviewData.questions
    )
}

#Preview("Answering") {
    AskView(
        viewModel: AskViewModel(
            answerer: PreviewQuestionAnswerer(),
            messages: [AskMessage(kind: .question, text: "How many wet nappies today?")],
            isAnswering: true
        ),
        child: AskViewPreviewData.child,
        suggestedQuestions: AskViewPreviewData.questions
    )
}

#Preview("Error") {
    AskView(
        viewModel: AskViewModel(
            answerer: PreviewQuestionAnswerer(),
            messages: [
                AskMessage(kind: .question, text: "How much did Ada sleep yesterday?"),
                AskMessage(kind: .error, text: "Something went wrong answering that. Please try again."),
            ]
        ),
        child: AskViewPreviewData.child,
        suggestedQuestions: AskViewPreviewData.questions
    )
}
