import SwiftUI

func summaryVariable(_ text: String) -> AttributedString {
    var a = AttributedString(text)
    a.swiftUI.foregroundColor = Color.accentColor
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
