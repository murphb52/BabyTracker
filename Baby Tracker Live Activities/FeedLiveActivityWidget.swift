import ActivityKit
import BabyTrackerDomain
import BabyTrackerLiveActivities
import SwiftUI
import WidgetKit

struct FeedLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FeedLiveActivityAttributes.self) { context in
            FeedLiveActivityContentView(state: context.state)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.primary)
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
                Image(systemName: symbolName(for: compactDynamicIslandMetric(for: context.state).kind))
            } compactTrailing: {
                compactTimerText(since: compactDynamicIslandMetric(for: context.state).date)
            } minimal: {
                Image(systemName: symbolName(for: .sleep))
            }
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

    private func compactDynamicIslandMetric(
        for state: FeedLiveActivityAttributes.ContentState
    ) -> (kind: BabyEventKind, date: Date) {
        if let activeSleepStartedAt = state.activeSleepStartedAt {
            return (kind: .sleep, date: activeSleepStartedAt)
        }

        var candidateEvents: [(kind: BabyEventKind, date: Date)] = [
            (kind: state.lastFeedKind, date: state.lastFeedAt)
        ]

        if let lastSleepAt = state.lastSleepAt {
            candidateEvents.append((kind: .sleep, date: lastSleepAt))
        }

        if let lastNappyAt = state.lastNappyAt {
            candidateEvents.append((kind: .nappy, date: lastNappyAt))
        }

        return candidateEvents.max(by: { $0.date < $1.date })
            ?? (kind: state.lastFeedKind, date: state.lastFeedAt)
    }

    @ViewBuilder
    private func compactTimerText(since date: Date) -> some View {
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
