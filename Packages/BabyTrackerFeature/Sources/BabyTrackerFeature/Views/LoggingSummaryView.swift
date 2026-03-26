import SwiftUI

func summaryVariable(_ text: String, color: Color = .accentColor) -> AttributedString {
    var a = AttributedString(text)
    a.swiftUI.foregroundColor = color
    return a
}

struct LoggingSummaryView: View {
    let sentence: AttributedString

    var body: some View {
        Section {
            Text(sentence)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
    }
}
