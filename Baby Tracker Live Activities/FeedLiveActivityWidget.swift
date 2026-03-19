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
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: symbolName(for: context.state.lastFeedKind))
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.childName)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(feedTitle(for: context.state.lastFeedKind))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.lastFeedAt, style: .timer)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("Last \(context.state.lastFeedAt.formatted(.dateTime.hour().minute()))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: symbolName(for: context.state.lastFeedKind))
            } compactTrailing: {
                Text(context.state.lastFeedAt, style: .timer)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: symbolName(for: context.state.lastFeedKind))
            }
        }
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
