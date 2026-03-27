import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI

struct FeedLiveActivityContentView: View {
    let state: FeedLiveActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 10) {
            Text(state.childName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(spacing: 8) {
                metricTile(
                    title: "Feed",
                    icon: symbolName(for: state.lastFeedKind),
                    color: eventAccentColor(for: .bottleFeed)
                ) {
                    Text(state.lastFeedAt, style: .timer)
                }

                metricTile(
                    title: state.activeSleepStartedAt == nil ? "Since sleep" : "Asleep",
                    icon: symbolName(for: .sleep),
                    color: eventAccentColor(for: .sleep)
                ) {
                    if let activeSleepStartedAt = state.activeSleepStartedAt {
                        Text(activeSleepStartedAt, style: .timer)
                    } else if let lastSleepAt = state.lastSleepAt {
                        Text(lastSleepAt, style: .timer)
                    } else {
                        Text("—")
                    }
                }

                metricTile(
                    title: "Nappy",
                    icon: symbolName(for: .nappy),
                    color: eventAccentColor(for: .nappy)
                ) {
                    if let lastNappyAt = state.lastNappyAt {
                        Text(lastNappyAt, style: .timer)
                    } else {
                        Text("—")
                    }
                }
            }

            if let stopURL = stopSleepURL {
                Link(destination: stopURL) {
                    Label("Stop Sleep", systemImage: "stop.fill")
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(eventAccentColor(for: .sleep))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var stopSleepURL: URL? {
        guard state.activeSleepStartedAt != nil else {
            return nil
        }

        return FeedLiveActivityDeepLink.endSleepURL(childID: state.childID)
    }

    private func metricTile(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder value: () -> some View
    ) -> some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: icon)
                    .frame(width: 14)
                Text(title)
            }
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(color)
                .frame(height: 16)

            value()
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.primary)
                .frame(height: 24, alignment: .top)
        }
        .frame(maxWidth: .infinity)
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

    private func eventAccentColor(for kind: BabyEventKind) -> Color {
        switch kind {
        case .breastFeed:
            Color(red: 0.84, green: 0.29, blue: 0.42)
        case .bottleFeed:
            Color(red: 0.15, green: 0.56, blue: 0.72)
        case .sleep:
            Color(red: 0.29, green: 0.33, blue: 0.73)
        case .nappy:
            Color(red: 0.74, green: 0.47, blue: 0.16)
        }
    }
}
