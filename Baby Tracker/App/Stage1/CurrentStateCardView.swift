import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct CurrentStateCardView: View {
    let summary: CurrentStateSummaryViewState?

    var body: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: symbolName(for: summary.lastEvent.kind))
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(summary.lastEvent.title)
                            .font(.headline)
                            .accessibilityIdentifier("current-status-last-event-value")

                        if let detailText = summary.lastEvent.detailText {
                            Text(detailText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("current-status-last-event-detail")
                        }
                    }

                    Spacer()
                }

                Divider()

                statusRow(
                    title: "Last logged",
                    identifier: "current-status-last-logged-value"
                ) {
                    Text(summary.lastEvent.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                }
 
                if let lastFeed = summary.lastFeed {
                    statusRow(
                        title: "Since last feed",
                        identifier: "current-status-since-last-feed-value"
                    ) {
                        relativeTimeText(for: lastFeed.lastFeedAt)
                    }
                    statusRow(
                        title: "Feeds today",
                        identifier: "current-status-feeds-today-value"
                    ) {
                        Text("\(lastFeed.feedsTodayCount)")
                    }
                } else {
                    statusRow(
                        title: "Since last feed",
                        identifier: "current-status-since-last-feed-value"
                    ) {
                        Text("No feeds yet")
                    }
                    statusRow(
                        title: "Feeds today",
                        identifier: "current-status-feeds-today-value"
                    ) {
                        Text("0")
                    }
                }

                if let lastNappy = summary.lastNappy {
                    statusRow(
                        title: "Last nappy",
                        identifier: "current-status-last-nappy-value"
                    ) {
                        relativeTimeText(for: lastNappy.occurredAt)
                    }
                } else {
                    statusRow(
                        title: "Last nappy",
                        identifier: "current-status-last-nappy-value"
                    ) {
                        Text("No nappies yet")
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("current-status-card")
        } else {
            Text("No events logged yet. Use Quick Log below to add the first event.")
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("current-status-empty-state")
        }
    }

    private func statusRow<Value: View>(
        title: String,
        identifier: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            value()
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(identifier)
        }
        .font(.subheadline)
    }

    private func relativeTimeText(for date: Date) -> some View {
        TimelineView(.everyMinute) { context in
            Text(relativeText(for: date, relativeTo: context.date))
        }
    }

    private func relativeText(
        for date: Date,
        relativeTo referenceDate: Date
    ) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: referenceDate)
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
