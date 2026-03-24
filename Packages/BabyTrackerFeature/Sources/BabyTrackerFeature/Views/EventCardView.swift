import BabyTrackerDomain
import SwiftUI

public struct EventCardView: View {
    let event: EventCardViewState

    public init(event: EventCardViewState) {
        self.event = event
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(BabyEventStyle.backgroundColor(for: event.kind))
                    .frame(width: 36, height: 36)

                Image(systemName: BabyEventStyle.systemImage(for: event.kind))
                    .font(.headline)
                    .foregroundStyle(BabyEventStyle.accentColor(for: event.kind))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)

                Text(event.detailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Text(event.timestampText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BabyEventStyle.cardFillColor(for: event.kind))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BabyEventStyle.accentColor(for: event.kind).opacity(0.16), lineWidth: 1)
        )
    }
}
