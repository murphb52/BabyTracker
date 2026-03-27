import BabyTrackerDomain
import SwiftUI

public struct CurrentStatusCardView: View {
    let status: CurrentStatusCardViewState

    public init(status: CurrentStatusCardViewState) {
        self.status = status
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statusRow(
                title: "Time since last feed",
                systemImage: "drop.fill",
                iconTint: BabyEventStyle.accentColor(for: .bottleFeed),
                identifier: "current-status-time-since-last-feed"
            ) {
                if let lastFeedAt = status.timeSinceLastFeedAt {
                    relativeTimeText(for: lastFeedAt)
                } else {
                    Text("No feeds yet")
                }
            }

            Divider()

            statusRow(
                title: "Feeds today",
                systemImage: "list.number",
                iconTint: BabyEventStyle.accentColor(for: .breastFeed),
                identifier: "current-status-feeds-today"
            ) {
                Text("\(status.feedsTodayCount)")
            }

            Divider()

            statusRow(
                title: "Time since last nappy",
                systemImage: BabyEventStyle.systemImage(for: .nappy),
                iconTint: BabyEventStyle.accentColor(for: .nappy),
                identifier: "current-status-time-since-last-nappy"
            ) {
                if let lastNappyAt = status.timeSinceLastNappyAt {
                    relativeTimeText(for: lastNappyAt)
                } else {
                    Text("No nappies yet")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-status-card")
    }

    private func statusRow<Value: View>(
        title: String,
        systemImage: String,
        iconTint: Color,
        identifier: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 18)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            value()
                .font(.headline)
                .multilineTextAlignment(.trailing)
                .accessibilityIdentifier(identifier)
        }
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
