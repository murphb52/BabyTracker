import BabyTrackerDomain
import SwiftUI

public struct CurrentStatusCardView: View {
    let status: CurrentStatusCardViewState

    public init(status: CurrentStatusCardViewState) {
        self.status = status
    }

    private var showSleepRow: Bool {
        status.lastSleep?.isActive != true
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showSleepRow {
                statusRow(
                    title: "Last sleep",
                    systemImage: BabyEventStyle.systemImage(for: .sleep),
                    iconTint: BabyEventStyle.accentColor(for: .sleep),
                    identifier: "current-status-sleep"
                ) {
                    sleepRowValue
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))

                Divider()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

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
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.35), value: showSleepRow)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("current-status-card")
    }

    @ViewBuilder
    private var sleepRowValue: some View {
        if let endedAt = status.lastSleep?.endedAt {
            relativeTimeText(for: endedAt)
        } else {
            Text("No sleep yet")
        }
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
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(relativeText(for: date, relativeTo: Date()))
        }
    }

    private func relativeText(
        for date: Date,
        relativeTo referenceDate: Date
    ) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: referenceDate)
    }
}

#Preview("Sleep row hidden (child asleep)") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: LastSleepSummaryViewState(isActive: true, startedAt: Date().addingTimeInterval(-4_500), endedAt: nil),
        timeSinceLastFeedAt: Date().addingTimeInterval(-5_400),
        feedsTodayCount: 4,
        timeSinceLastNappyAt: Date().addingTimeInterval(-7_200)
    ))
    .padding()
}

#Preview("Not sleeping") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: LastSleepSummaryViewState(isActive: false, startedAt: Date().addingTimeInterval(-18_000), endedAt: Date().addingTimeInterval(-10_800)),
        timeSinceLastFeedAt: Date().addingTimeInterval(-3_600),
        feedsTodayCount: 6,
        timeSinceLastNappyAt: Date().addingTimeInterval(-5_400)
    ))
    .padding()
}

#Preview("No data") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: nil,
        timeSinceLastFeedAt: nil,
        feedsTodayCount: 0,
        timeSinceLastNappyAt: nil
    ))
    .padding()
}
