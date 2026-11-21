import SwiftUI

struct AskMessageBubbleView: View {
    let message: AskMessage

    var body: some View {
        switch message.kind {
        case .question:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.accentColor, in: .rect(cornerRadius: 18))
            }
        case .answer:
            HStack {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
                    .textSelection(.enabled)
                Spacer(minLength: 48)
            }
        case .notice:
            Text(message.text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        case .error:
            HStack {
                Label(message.text, systemImage: "exclamationmark.triangle")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15), in: .rect(cornerRadius: 18))
                Spacer(minLength: 48)
            }
        }
    }
}

#Preview("All message kinds") {
    VStack(spacing: 12) {
        AskMessageBubbleView(message: AskMessage(kind: .question, text: "When did Ada last feed?"))
        AskMessageBubbleView(message: AskMessage(kind: .answer, text: "Ada last fed 2 hours ago: a 120 ml bottle of formula."))
        AskMessageBubbleView(message: AskMessage(kind: .notice, text: "That conversation got long, so I started a fresh one."))
        AskMessageBubbleView(message: AskMessage(kind: .error, text: "Something went wrong answering that. Please try again."))
    }
    .padding()
}
