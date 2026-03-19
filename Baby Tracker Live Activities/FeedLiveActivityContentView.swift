import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI

struct FeedLiveActivityContentView: View {
    let state: FeedLiveActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbolName(for: state.lastFeedKind))
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(state.childName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text(feedTitle(for: state.lastFeedKind))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("Last \(formattedLastFeedTime)")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                Text(state.lastFeedAt, style: .timer)
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .lineLimit(1)
            }
            .font(.footnote.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedLastFeedTime: String {
        state.lastFeedAt.formatted(.dateTime.hour().minute())
    }

    private func feedTitle(for kind: BabyEventKind) -> String {
        switch kind {
        case .breastFeed:
            "Breast Feed"
        case .bottleFeed:
            "Bottle Feed"
        case .sleep:
            "Sleep"
        case .nappy:
            "Nappy"
        }
    }

    private func symbolName(for kind: BabyEventKind) -> String {
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
}
