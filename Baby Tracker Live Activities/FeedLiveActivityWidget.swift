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
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 6) {
                        metricIcon(symbol: symbolName(for: context.state.lastFeedKind), color: eventAccentColor(for: .bottleFeed))
                        metricIcon(symbol: symbolName(for: .sleep), color: eventAccentColor(for: .sleep))
                        metricIcon(symbol: symbolName(for: .nappy), color: eventAccentColor(for: .nappy))
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.childName)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        metricRow(label: "Feed", valueDate: context.state.lastFeedAt)
                        metricRow(
                            label: context.state.activeSleepStartedAt == nil ? "Since sleep" : "Asleep",
                            valueDate: context.state.activeSleepStartedAt ?? context.state.lastSleepAt
                        )
                        metricRow(label: "Nappy", valueDate: context.state.lastNappyAt)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if let stopURL = stopSleepURL(for: context.state) {
                        Link(destination: stopURL) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(eventAccentColor(for: .sleep))
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text("Timers update live while this activity is visible.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: symbolName(for: .sleep))
            } compactTrailing: {
                if let activeSleepStartedAt = context.state.activeSleepStartedAt {
                    Text(activeSleepStartedAt, style: .timer)
                        .monospacedDigit()
                } else {
                    Text(context.state.lastFeedAt, style: .timer)
                        .monospacedDigit()
                }
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

    private func metricRow(label: String, valueDate: Date?) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(.secondary)
            if let valueDate {
                Text(valueDate, style: .timer)
                    .monospacedDigit()
            } else {
                Text("—")
            }
        }
        .font(.caption2.weight(.medium))
        .lineLimit(1)
    }

    private func metricIcon(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
    }

    private func stopSleepURL(for state: FeedLiveActivityAttributes.ContentState) -> URL? {
        guard state.activeSleepStartedAt != nil else {
            return nil
        }

        return FeedLiveActivityDeepLink.endSleepURL(childID: state.childID)
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
