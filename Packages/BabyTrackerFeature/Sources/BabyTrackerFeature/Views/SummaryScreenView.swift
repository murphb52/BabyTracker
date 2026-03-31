import SwiftUI

public struct SummaryScreenView: View {
    let summary: SummaryScreenState

    @State private var selectedRange: SummaryTimeRange = .today

    public init(summary: SummaryScreenState) {
        self.summary = summary
    }

    public var body: some View {
        let snapshot = SummaryMetricsCalculator.makeSnapshot(
            from: summary.events,
            range: selectedRange
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                rangePicker

                if snapshot.eventCount == 0 {
                    emptyState
                } else {
                    topMetrics(snapshot: snapshot)
                    chartSection(snapshot: snapshot)
                    advancedSummaryLink
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(SummaryTimeRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summary.emptyStateTitle)
                .font(.headline)

            Text(summary.emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .accessibilityIdentifier("summary-empty-state")
    }

    private func topMetrics(snapshot: SummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Metrics")
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                metricCard(
                    title: "Feeds",
                    value: "\(snapshot.totalFeeds)",
                    subtitle: subtitleForFeedAverage(snapshot),
                    symbol: "drop.fill",
                    tint: .blue
                )

                metricCard(
                    title: "Nappy Changes",
                    value: "\(snapshot.totalNappies)",
                    subtitle: "Wet: \(snapshot.wetNappyCount) • Dirty: \(snapshot.dirtyNappyCount)",
                    symbol: "checklist.checked",
                    tint: .green
                )

                metricCard(
                    title: "Sleep",
                    value: formatMinutes(snapshot.totalSleepMinutes),
                    subtitle: sleepRangeSubtitle(snapshot),
                    symbol: "moon.zzz.fill",
                    tint: .indigo
                )

                metricCard(
                    title: "Logging Streak",
                    value: "\(snapshot.loggingStreakDays) day\(snapshot.loggingStreakDays == 1 ? "" : "s")",
                    subtitle: "Consecutive days with logs",
                    symbol: "flame.fill",
                    tint: .orange
                )
            }
        }
    }

    private func chartSection(snapshot: SummarySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends")
                .font(.headline)

            chartCard(
                title: "7-Day Activity",
                subtitle: "Total events per day"
            ) {
                miniBarChart(
                    points: snapshot.dailyEventCounts.map { ($0.label, $0.count) },
                    tint: .orange
                )
            }

            chartCard(
                title: "Feed Time of Day",
                subtitle: "Feeds by hour bucket"
            ) {
                miniBarChart(
                    points: snapshot.feedCountsByHour.map { ($0.label, $0.count) },
                    tint: Color.blue
                )
            }
        }
    }

    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Spacer()
            }

            Text(value)
                .font(.title3.weight(.bold))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private var advancedSummaryLink: some View {
        NavigationLink {
            AdvancedSummaryView(
                summary: summary,
                initialSelection: .range(selectedRange)
            )
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("More Information")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Open feeds, sleep, nappies, and activity details for a range or a specific day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .padding(16)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private func chartCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(14)
        .background(cardBackground)
    }

    private func miniBarChart(points: [(String, Int)], tint: Color) -> some View {
        let maxValue = max(1, points.map(\.1).max() ?? 0)

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(tint.gradient)
                        .frame(height: max(6, (CGFloat(point.1) / CGFloat(maxValue)) * 84))
                        .overlay(alignment: .top) {
                            if point.1 > 0 {
                                Text("\(point.1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .offset(y: -16)
                            }
                        }

                    Text(point.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .bottom)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8)
    }

    private func subtitleForFeedAverage(_ snapshot: SummarySnapshot) -> String {
        guard let average = snapshot.averageFeedDurationMinutes else {
            return "No breast feed duration data"
        }

        return "Average duration: \(average) min"
    }

    private func sleepRangeSubtitle(_ snapshot: SummarySnapshot) -> String {
        guard let shortest = snapshot.shortestSleepBlockMinutes,
              let longest = snapshot.longestSleepBlockMinutes else {
            return "No completed sleeps"
        }

        return "Shortest: \(shortest)m • Longest: \(longest)m"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes)m"
        }

        return "\(hours)h \(remainingMinutes)m"
    }
}

#Preview("With Data") {
    NavigationStack {
        SummaryScreenView(summary: SummaryScreenPreviewFactory.summaryState)
    }
}

#Preview("Empty") {
    NavigationStack {
        SummaryScreenView(
            summary: SummaryScreenState(
                events: [],
                emptyStateTitle: "No summary data yet",
                emptyStateMessage: "Log feeds, sleep, and nappies to unlock trends."
            )
        )
    }
}
