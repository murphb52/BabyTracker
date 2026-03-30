import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI

struct FeedLiveActivityContentView: View {
    let state: FeedLiveActivityAttributes.ContentState
    let showsStopSleepAction: Bool

    init(
        state: FeedLiveActivityAttributes.ContentState,
        showsStopSleepAction: Bool = true
    ) {
        self.state = state
        self.showsStopSleepAction = showsStopSleepAction
    }

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(state.childName)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(alignment: .center, spacing: 4) {
                metricTile(
                    title: "Feed",
                    icon: symbolName(for: state.lastFeedKind),
                    color: eventAccentColor(for: .bottleFeed)
                ) {
                    Text(state.lastFeedAt, style: .timer).timerStyle()
                }

                metricTile(
                    title: state.activeSleepStartedAt == nil ? "Since sleep" : "Asleep",
                    icon: symbolName(for: .sleep),
                    color: eventAccentColor(for: .sleep)
                ) {
                    if let activeSleepStartedAt = state.activeSleepStartedAt {
                        Text(activeSleepStartedAt, style: .timer).timerStyle()
                    } else if let lastSleepAt = state.lastSleepAt {
                        Text(lastSleepAt, style: .timer).timerStyle()
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
                        Text(lastNappyAt, style: .timer).timerStyle()
                    } else {
                        Text("—")
                    }
                }
            }

            if showsStopSleepAction, let stopURL = stopSleepURL {
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
        .padding(.vertical, 4)
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
        VStack(alignment: .center, spacing: 3) {
            HStack(alignment: .center, spacing: 4) {
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
                .frame(height: 24, alignment: .center)
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

#Preview("Recent Feed") {
    FeedLiveActivityContentView(state: .previewRecentFeed)
}

#Preview("Active Sleep") {
    FeedLiveActivityContentView(state: .previewActiveSleep)
}

#Preview("Missing Metrics") {
    FeedLiveActivityContentView(state: .previewMissingMetrics)
}

#Preview("Expanded Metrics Only") {
    FeedLiveActivityContentView(
        state: .previewActiveSleep,
        showsStopSleepAction: false
    )
}

extension Text {
    func timerStyle() -> some View {
        HStack(alignment: .center) {
            Spacer()
            Text("00:00:00")
                .hidden()
                .overlay {
                    self
                }
            Spacer()
        }
    }
}
