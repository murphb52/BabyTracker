import SwiftUI

struct AskInputBarView: View {
    let childName: String
    @Binding var draft: String
    let canSend: Bool
    let send: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Ask about \(childName)…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit(send)
                .accessibilityIdentifier("ask-input-field")

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send question")
            .accessibilityIdentifier("ask-send-button")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview("Empty") {
    AskInputBarView(childName: "Ada", draft: .constant(""), canSend: false, send: {})
}

#Preview("With draft") {
    AskInputBarView(childName: "Ada", draft: .constant("How much did Ada sleep yesterday?"), canSend: true, send: {})
}
