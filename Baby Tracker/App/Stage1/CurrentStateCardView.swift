import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI

struct CurrentStateCardView: View {
    let summary: CurrentStateSummaryViewState?

    var body: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(BabyEventStyle.backgroundColor(for: summary.lastEvent.kind))
                            .frame(width: 46, height: 46)

                        Image(systemName: BabyEventStyle.systemImage(for: summary.lastEvent.kind))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(BabyEventStyle.accentColor(for: summary.lastEvent.kind))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Latest Event")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(summary.lastEvent.title)
                            .font(.title3.weight(.semibold))
                            .accessibilityIdentifier("current-status-last-event-value")

                        if let detailText = summary.lastEvent.detailText {
                            Text(detailText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("current-status-last-event-detail")
                        }
                    }

                    Spacer()

                    Text(summary.lastEvent.occurredAt, format: .dateTime.hour().minute())
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                statusRow(
                    title: "Last logged",
                    identifier: "current-status-last-logged-value"
                ) {
                    Text(summary.lastEvent.occurredAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 12
                ) {
                    metricTile(
                        title: "Since last feed",
                        valueIdentifier: "current-status-since-last-feed-value"
                    ) {
                        if let lastFeed = summary.lastFeed {
                            relativeTimeText(for: lastFeed.lastFeedAt)
                        } else {
                            Text("No feeds yet")
                        }
                    }

                    metricTile(
                        title: "Feeds today",
                        valueIdentifier: "current-status-feeds-today-value"
                    ) {
                        Text("\(summary.lastFeed?.feedsTodayCount ?? 0)")
                    }

                    metricTile(
                        title: "Last nappy",
                        valueIdentifier: "current-status-last-nappy-value"
                    ) {
                        if let lastNappy = summary.lastNappy {
                            relativeTimeText(for: lastNappy.occurredAt)
                        } else {
                            Text("No nappies yet")
                        }
                    }

                    metricTile(
                        title: summary.lastSleep?.isActive == true ? "Sleep now" : "Last sleep",
                        valueIdentifier: "current-status-last-sleep-value"
                    ) {
                        if let lastSleep = summary.lastSleep {
                            if lastSleep.isActive {
                                Text("In progress")
                            } else if let endedAt = lastSleep.endedAt {
                                relativeTimeText(for: endedAt)
                            }
                        } else {
                            Text("No sleep yet")
                        }
                    }
                }

                if let lastSleep = summary.lastSleep, lastSleep.isActive {
                    metricTile(
                        title: "Since sleep started",
                        valueIdentifier: "current-status-since-sleep-started-value"
                    ) {
                        relativeTimeText(for: lastSleep.startedAt)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("current-status-card")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("No events logged yet")
                    .font(.headline)

                Text("Use Quick Log below to add the first event.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            )
                .accessibilityIdentifier("current-status-empty-state")
        }
    }

    private func metricTile<Value: View>(
        title: String,
        valueIdentifier: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            value()
                .font(.headline)
                .accessibilityIdentifier(valueIdentifier)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
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
}
