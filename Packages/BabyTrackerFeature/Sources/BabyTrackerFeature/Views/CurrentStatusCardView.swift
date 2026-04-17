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
                    subtitle: lastSleepDetailText,
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
                title: "Last breast feed",
                subtitle: status.lastBreastFeed?.detailText,
                systemImage: BabyEventStyle.systemImage(for: .breastFeed),
                iconTint: BabyEventStyle.accentColor(for: .breastFeed),
                identifier: "current-status-last-breast-feed"
            ) {
                if let lastBreastFeed = status.lastBreastFeed {
                    relativeTimeText(for: lastBreastFeed.occurredAt)
                } else {
                    Text("No feeds yet")
                }
            }

            Divider()

            statusRow(
                title: "Last bottle feed",
                subtitle: status.lastBottleFeed?.detailText,
                systemImage: BabyEventStyle.systemImage(for: .bottleFeed),
                iconTint: BabyEventStyle.accentColor(for: .bottleFeed),
                identifier: "current-status-last-bottle-feed"
            ) {
                if let lastBottleFeed = status.lastBottleFeed {
                    relativeTimeText(for: lastBottleFeed.occurredAt)
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
                title: "Last nappy",
                subtitle: status.lastNappy?.detailText,
                systemImage: BabyEventStyle.systemImage(for: .nappy),
                iconTint: BabyEventStyle.accentColor(for: .nappy),
                identifier: "current-status-last-nappy"
            ) {
                if let lastNappy = status.lastNappy {
                    relativeTimeText(for: lastNappy.occurredAt)
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

    private var lastSleepDetailText: String? {
        guard let sleep = status.lastSleep,
              !sleep.isActive,
              let endedAt = sleep.endedAt else {
            return nil
        }
        let minutes = max(1, Int(endedAt.timeIntervalSince(sleep.startedAt) / 60))
        return DurationText.short(minutes: minutes, minuteStyle: .word)
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
        subtitle: String? = nil,
        systemImage: String,
        iconTint: Color,
        identifier: String,
        @ViewBuilder value: () -> Value
    ) -> some View {
        HStack(alignment: subtitle == nil ? .firstTextBaseline : .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconTint)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

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

#Preview("Active sleep (sleep row hidden)") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: LastSleepSummaryViewState(isActive: true, startedAt: Date().addingTimeInterval(-4_500), endedAt: nil),
        lastBreastFeed: LastEventSummaryViewState(kind: .breastFeed, title: "Breast Feed", detailText: "20 min • Left", occurredAt: Date().addingTimeInterval(-5_400)),
        lastBottleFeed: LastEventSummaryViewState(kind: .bottleFeed, title: "Bottle Feed", detailText: "120 mL • Formula", occurredAt: Date().addingTimeInterval(-9_000)),
        feedsTodayCount: 4,
        lastNappy: LastNappySummaryViewState(title: "Nappy", detailText: "Poo • Medium • Yellow", occurredAt: Date().addingTimeInterval(-7_200))
    ))
    .padding()
}

#Preview("Not sleeping") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: LastSleepSummaryViewState(isActive: false, startedAt: Date().addingTimeInterval(-18_000), endedAt: Date().addingTimeInterval(-10_800)),
        lastBreastFeed: LastEventSummaryViewState(kind: .breastFeed, title: "Breast Feed", detailText: "15 min • Right", occurredAt: Date().addingTimeInterval(-3_600)),
        lastBottleFeed: LastEventSummaryViewState(kind: .bottleFeed, title: "Bottle Feed", detailText: "180 mL • Breast Milk", occurredAt: Date().addingTimeInterval(-6_300)),
        feedsTodayCount: 6,
        lastNappy: LastNappySummaryViewState(title: "Nappy", detailText: "Pee • Light", occurredAt: Date().addingTimeInterval(-5_400))
    ))
    .padding()
}

#Preview("No data") {
    CurrentStatusCardView(status: CurrentStatusCardViewState(
        lastSleep: nil,
        lastBreastFeed: nil,
        lastBottleFeed: nil,
        feedsTodayCount: 0,
        lastNappy: nil
    ))
    .padding()
}
