import ActivityKit
import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI
import WidgetKit

struct FeedLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FeedLiveActivityAttributes.self) { context in
            FeedLiveActivityContentView(state: context.state)
                .activityBackgroundTint(Color(red: 0.12, green: 0.15, blue: 0.24))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(FeedLiveActivityDeepLink.endSleepURL(childID: context.state.childID))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    FeedLiveActivityContentView(
                        state: context.state,
                        showsStopSleepAction: false
                    )
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if let stopSleepURL = FeedLiveActivityDeepLink.endSleepURL(childID: context.state.childID),
                       context.state.activeSleepStartedAt != nil {
                        Link(destination: stopSleepURL) {
                            Label("Stop Sleep", systemImage: "stop.fill")
                                .font(.caption.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } compactLeading: {
                compactLeadingView(for: context.state)
            } compactTrailing: {
                compactTrailingView(for: context.state)
            } minimal: {
                minimalView(for: context.state)
            }
        }
    }

    @ViewBuilder
    private func compactLeadingView(for state: FeedLiveActivityAttributes.ContentState) -> some View {
        let compactMetric = compactDynamicIslandMetric(for: state)
        Image(systemName: symbolName(for: compactMetric))
            .foregroundStyle(eventAccentColor(for: compactMetric.kind))
    }

    @ViewBuilder
    private func compactTrailingView(for state: FeedLiveActivityAttributes.ContentState) -> some View {
        let compactMetric = compactDynamicIslandMetric(for: state)
        compactTimerText(
            since: compactMetric.date,
            color: eventAccentColor(for: compactMetric.kind)
        )
    }

    @ViewBuilder
    private func minimalView(for state: FeedLiveActivityAttributes.ContentState) -> some View {
        let compactMetric = compactDynamicIslandMetric(for: state)
        Image(systemName: symbolName(for: compactMetric))
            .foregroundStyle(eventAccentColor(for: compactMetric.kind))
    }

    private func symbolName(for metric: CompactDynamicIslandMetric) -> String {
        switch metric.kind {
        case .breastFeed:
            "heart.text.square"
        case .bottleFeed:
            "drop.circle"
        case .sleep:
            metric.isActiveSleep ? "zzz" : "bed.double.fill"
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

    private struct CompactDynamicIslandMetric {
        let kind: BabyEventKind
        let date: Date
        let isActiveSleep: Bool
    }

    private func compactDynamicIslandMetric(
        for state: FeedLiveActivityAttributes.ContentState
    ) -> CompactDynamicIslandMetric {
        if let activeSleepStartedAt = state.activeSleepStartedAt {
            return CompactDynamicIslandMetric(
                kind: .sleep,
                date: activeSleepStartedAt,
                isActiveSleep: true
            )
        }

        var candidateEvents: [CompactDynamicIslandMetric] = [
            CompactDynamicIslandMetric(
                kind: state.lastFeedKind,
                date: state.lastFeedAt,
                isActiveSleep: false
            )
        ]

        if let lastSleepAt = state.lastSleepAt {
            candidateEvents.append(
                CompactDynamicIslandMetric(
                    kind: .sleep,
                    date: lastSleepAt,
                    isActiveSleep: false
                )
            )
        }

        if let lastNappyAt = state.lastNappyAt {
            candidateEvents.append(
                CompactDynamicIslandMetric(
                    kind: .nappy,
                    date: lastNappyAt,
                    isActiveSleep: false
                )
            )
        }

        return candidateEvents.max(by: { $0.date < $1.date })
            ?? CompactDynamicIslandMetric(
                kind: state.lastFeedKind,
                date: state.lastFeedAt,
                isActiveSleep: false
            )
    }

    @ViewBuilder
    private func compactTimerText(since date: Date, color: Color) -> some View {
        Text(
            timerInterval: date...Date.distantFuture,
            pauseTime: nil,
            countsDown: false,
            showsHours: false
        )
        .font(.caption2.weight(.semibold))
        .monospacedDigit()
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .foregroundStyle(color)
        .frame(width: 40, alignment: .trailing)
    }
}

#Preview("Live Activity", as: .content, using: FeedLiveActivityAttributes.preview) {
    FeedLiveActivityWidget()
} contentStates: {
    FeedLiveActivityAttributes.ContentState.previewRecentFeed
    FeedLiveActivityAttributes.ContentState.previewActiveSleep
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: FeedLiveActivityAttributes.preview) {
    FeedLiveActivityWidget()
} contentStates: {
    FeedLiveActivityAttributes.ContentState.previewRecentFeed
    FeedLiveActivityAttributes.ContentState.previewActiveSleep
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: FeedLiveActivityAttributes.preview) {
    FeedLiveActivityWidget()
} contentStates: {
    FeedLiveActivityAttributes.ContentState.previewRecentFeed
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: FeedLiveActivityAttributes.preview) {
    FeedLiveActivityWidget()
} contentStates: {
    FeedLiveActivityAttributes.ContentState.previewMissingMetrics
}
