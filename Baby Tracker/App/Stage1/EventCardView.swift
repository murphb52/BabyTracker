import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct EventCardView: View {
    let event: EventCardViewState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImageName(for: event.kind))
                .font(.title3)
                .foregroundStyle(accentColor(for: event.kind))
                .frame(width: 28)

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
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func systemImageName(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "heart.text.square"
        case .bottleFeed:
            "drop.circle"
        case .sleep:
            "bed.double"
        case .nappy:
            "checklist"
        }
    }

    private func accentColor(for kind: BabyEventKind) -> Color {
        switch kind {
        case .breastFeed:
            .pink
        case .bottleFeed:
            .teal
        case .sleep:
            .indigo
        case .nappy:
            .orange
        }
    }
}
