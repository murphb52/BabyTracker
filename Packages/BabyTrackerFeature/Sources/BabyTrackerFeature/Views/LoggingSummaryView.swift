import SwiftUI

struct LoggingSummaryView: View {
    let sentence: String

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
