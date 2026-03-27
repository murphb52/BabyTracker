import SwiftUI

func summaryVariable(_ text: String, color: Color = .accentColor) -> AttributedString {
    var a = AttributedString(text)
    a.swiftUI.foregroundColor = color
    a.swiftUI.font = .body.weight(.semibold)
    return a
}

struct LoggingSummaryView: View {
    let sentence: AttributedString

    var body: some View {
        Section {
            Text(sentence)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
    }
}
