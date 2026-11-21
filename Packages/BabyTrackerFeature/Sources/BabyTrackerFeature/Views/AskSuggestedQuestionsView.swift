import SwiftUI

struct AskSuggestedQuestionsView: View {
    let childName: String
    let questions: [String]
    let select: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Ask about \(childName)", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                Text("Ask questions about feeds, sleep, nappies and more. Answers are worked out on this iPhone from what you've logged.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    Button {
                        select(question)
                    } label: {
                        Text(question)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("ask-suggested-question")
                }
            }
        }
    }
}

#Preview("Suggestions") {
    AskSuggestedQuestionsView(
        childName: "Ada",
        questions: AskSuggestedQuestions.make(childName: "Ada", loggedKinds: [.bottleFeed, .sleep, .nappy]),
        select: { _ in }
    )
    .padding()
}

#Preview("No data yet") {
    AskSuggestedQuestionsView(
        childName: "Ada",
        questions: AskSuggestedQuestions.make(childName: "Ada", loggedKinds: []),
        select: { _ in }
    )
    .padding()
}
