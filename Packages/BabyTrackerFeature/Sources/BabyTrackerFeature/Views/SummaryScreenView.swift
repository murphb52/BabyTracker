import BabyTrackerDomain
import SwiftUI

private enum SummaryTab: String, CaseIterable {
    case today = "Today"
    case trends = "Trends"
}

public struct SummaryScreenView: View {
    let viewModel: SummaryViewModel

    @State private var selectedTab: SummaryTab = .today
    @State private var selectedTrendsRange: TrendsTimeRange = .sevenDays

    public init(viewModel: SummaryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                tabPicker

                switch selectedTab {
                case .today:
                    todayTabContent
                case .trends:
                    trendsTabContent
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(SummaryTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Today Tab

    private var todayTabContent: some View {
        let data = TodaySummaryCalculator.makeData(from: viewModel.events)
        let hasAnyTodayData = data.bottleCount > 0 || data.breastFeedCount > 0
            || data.totalSleepMinutes > 0 || data.totalNappies > 0

        return Group {
            if !hasAnyTodayData && viewModel.events.isEmpty {
                emptyStateCard(
                    title: viewModel.emptyStateTitle,
                    message: viewModel.emptyStateMessage
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    todayMetricGrid(data: data)
                    todayExtrasRow(data: data)
                }
            }
        }
    }

    private func todayMetricGrid(data: TodaySummaryData) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ],
            spacing: 12
        ) {
            bottleCard(data: data)
            breastCard(data: data)
            sleepCard(data: data)
            nappyCard(data: data)
        }
    }

    private func bottleCard(data: TodaySummaryData) -> some View {
        let volumeText = data.bottleCount == 0
            ? "0 mL"
            : "\(data.bottleTotalMilliliters) mL"

        let subtitle: String
        if data.bottleCount == 0 {
            subtitle = "No bottle feeds today"
        } else if let mins = data.minutesSinceLastFeed {
            subtitle = "\(data.bottleCount) feed\(data.bottleCount == 1 ? "" : "s") • last \(DurationText.short(minutes: mins)) ago"
        } else {
            subtitle = "\(data.bottleCount) feed\(data.bottleCount == 1 ? "" : "s")"
        }

        return metricCard(
            title: "Bottle",
            value: volumeText,
            subtitle: subtitle,
            symbol: "bottle.fill",
            tint: .blue
        )
    }

    private func breastCard(data: TodaySummaryData) -> some View {
        let durationText = data.breastFeedCount == 0
            ? "0m"
            : DurationText.short(minutes: data.breastFeedTotalMinutes)

        let subtitle: String
        if data.breastFeedCount == 0 {
            subtitle = "No breast feeds today"
        } else if let interval = data.averageFeedIntervalMinutes {
            subtitle = "\(data.breastFeedCount) feed\(data.breastFeedCount == 1 ? "" : "s") • avg \(DurationText.short(minutes: interval))"
        } else {
            subtitle = "\(data.breastFeedCount) feed\(data.breastFeedCount == 1 ? "" : "s")"
        }

        return metricCard(
            title: "Breast",
            value: durationText,
            subtitle: subtitle,
            symbol: "heart.fill",
            tint: .pink
        )
    }

    private func sleepCard(data: TodaySummaryData) -> some View {
        let totalText = data.totalSleepMinutes == 0
            ? "0m"
            : DurationText.short(minutes: data.totalSleepMinutes)

        let subtitle: String
        if data.totalSleepMinutes == 0 {
            subtitle = "No sleep logged today"
        } else {
            var parts: [String] = []
            if data.daytimeSleepMinutes > 0 {
                parts.append("Day \(DurationText.short(minutes: data.daytimeSleepMinutes))")
            }
            if data.nighttimeSleepMinutes > 0 {
                parts.append("Night \(DurationText.short(minutes: data.nighttimeSleepMinutes))")
            }
            if let longest = data.longestSleepBlockMinutes {
                parts.append("Longest \(DurationText.short(minutes: longest))")
            }
            subtitle = parts.joined(separator: " • ")
        }

        return metricCard(
            title: "Sleep",
            value: totalText,
            subtitle: subtitle,
            symbol: "moon.zzz.fill",
            tint: .indigo
        )
    }

    private func nappyCard(data: TodaySummaryData) -> some View {
        let subtitle: String
        if data.totalNappies == 0 {
            subtitle = "No nappy changes today"
        } else {
            var parts: [String] = []
            parts.append("Wet: \(data.wetInclusiveCount)")
            parts.append("Dirty: \(data.dirtyInclusiveCount)")
            if data.mixedNappyCount > 0 {
                parts.append("Mixed: \(data.mixedNappyCount)")
            }
            subtitle = parts.joined(separator: " • ")
        }

        return metricCard(
            title: "Nappies",
            value: "\(data.totalNappies)",
            subtitle: subtitle,
            symbol: "checklist.checked",
            tint: .green
        )
    }

    private func todayExtrasRow(data: TodaySummaryData) -> some View {
        VStack(spacing: 0) {
            if let mins = data.minutesSinceLastFeed {
                extrasRow(
                    symbol: "clock.fill",
                    tint: .orange,
                    label: "Last feed",
                    value: "\(DurationText.short(minutes: mins)) ago"
                )
                Divider().padding(.leading, 44)
            }

            if let interval = data.averageFeedIntervalMinutes {
                extrasRow(
                    symbol: "arrow.trianglehead.clockwise",
                    tint: .orange,
                    label: "Avg feed interval",
                    value: DurationText.short(minutes: interval)
                )
                Divider().padding(.leading, 44)
            }

            extrasRow(
                symbol: "flame.fill",
                tint: .orange,
                label: "Logging streak",
                value: "\(data.loggingStreakDays) day\(data.loggingStreakDays == 1 ? "" : "s")"
            )
        }
        .background(cardBackground)
    }

    private func extrasRow(symbol: String, tint: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Trends Tab

    private var trendsTabContent: some View {
        let data = TrendsSummaryCalculator.makeData(from: viewModel.events, range: selectedTrendsRange)
        let hasData = data.dailyBottle.contains { $0.count > 0 }
            || data.dailyBreastFeed.contains { $0.sessionCount > 0 }
            || data.dailySleep.contains { $0.totalMinutes > 0 }
            || data.dailyNappy.contains { $0.totalCount > 0 }

        return VStack(alignment: .leading, spacing: 12) {
            trendsRangePicker

            if !hasData {
                emptyStateCard(
                    title: "No data for this period",
                    message: "Try a broader range to see feeding, sleep, and nappy trends."
                )
            } else {
                bottleChartCard(data: data)
                breastChartCard(data: data)
                sleepChartCard(data: data)
                nappyChartCard(data: data)
                advancedSummaryLink
            }
        }
    }

    private var trendsRangePicker: some View {
        Picker("Range", selection: $selectedTrendsRange) {
            ForEach(TrendsTimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private func bottleChartCard(data: TrendsSummaryData) -> some View {
        let points = data.dailyBottle.map { ($0.label, $0.totalMilliliters) }
        let avgText = data.avgDailyBottleMilliliters.map { "Avg \($0) mL/day" }

        return chartCard(
            title: "Bottle Feeds",
            symbol: "bottle.fill",
            tint: .blue,
            subtitle: avgText ?? "No bottle feeds in this period"
        ) {
            miniBarChart(points: points, tint: .blue)
        }
    }

    private func breastChartCard(data: TrendsSummaryData) -> some View {
        let points = data.dailyBreastFeed.map { ($0.label, $0.sessionCount) }
        let avgText = data.avgDailyBreastFeedSessions.map { "Avg \($0) session\($0 == 1 ? "" : "s")/day" }

        return chartCard(
            title: "Breast Feeds",
            symbol: "heart.fill",
            tint: .pink,
            subtitle: avgText ?? "No breast feeds in this period"
        ) {
            miniBarChart(points: points, tint: .pink)
        }
    }

    private func sleepChartCard(data: TrendsSummaryData) -> some View {
        let points = data.dailySleep.map { ($0.label, $0.totalMinutes) }
        let avgText = data.avgDailySleepMinutes.map { "Avg \(DurationText.short(minutes: $0))/day" }

        return chartCard(
            title: "Sleep",
            symbol: "moon.zzz.fill",
            tint: .indigo,
            subtitle: avgText ?? "No sleep logged in this period"
        ) {
            miniBarChart(points: points, tint: .indigo, valueFormatter: { DurationText.short(minutes: $0) })
        }
    }

    private func nappyChartCard(data: TrendsSummaryData) -> some View {
        let avgText = data.avgDailyNappies.map { "Avg \($0)/day" }

        return chartCard(
            title: "Nappies",
            symbol: "checklist.checked",
            tint: .green,
            subtitle: avgText ?? "No nappy changes in this period"
        ) {
            stackedNappyChart(data: data.dailyNappy)
            nappyLegend
        }
    }

    // MARK: - Chart Components

    private func miniBarChart(
        points: [(String, Int)],
        tint: Color,
        valueFormatter: ((Int) -> String)? = nil
    ) -> some View {
        let maxValue = max(1, points.map(\.1).max() ?? 0)

        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                VStack(spacing: 4) {
                    if point.1 > 0 {
                        Text(valueFormatter?(point.1) ?? "\(point.1)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(tint.gradient)
                        .frame(height: max(4, (CGFloat(point.1) / CGFloat(maxValue)) * 80))

                    Text(point.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .bottom)
    }

    private func stackedNappyChart(data: [DailyNappyData]) -> some View {
        let maxTotal = max(1, data.map(\.totalCount).max() ?? 0)
        let barHeight: CGFloat = 80

        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    if day.totalCount > 0 {
                        Text("\(day.totalCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Stacked bar: wet (bottom, blue) / dirty (middle, brown) / mixed (top, yellow)
                    if day.totalCount == 0 {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 4)
                    } else {
                        VStack(spacing: 1) {
                            // Mixed (top)
                            if day.mixedCount > 0 {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.yellow.opacity(0.85))
                                    .frame(height: max(3, CGFloat(day.mixedCount) / CGFloat(maxTotal) * barHeight))
                            }

                            // Dirty (middle)
                            if day.dirtyCount > 0 {
                                Rectangle()
                                    .fill(Color.brown.opacity(0.75))
                                    .frame(height: max(3, CGFloat(day.dirtyCount) / CGFloat(maxTotal) * barHeight))
                            }

                            // Wet (bottom)
                            if day.wetCount > 0 {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.blue.opacity(0.6))
                                    .frame(height: max(3, CGFloat(day.wetCount) / CGFloat(maxTotal) * barHeight))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }

                    Text(day.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .bottom)
    }

    private var nappyLegend: some View {
        HStack(spacing: 12) {
            legendItem(color: .blue.opacity(0.6), label: "Wet")
            legendItem(color: .brown.opacity(0.75), label: "Dirty")
            legendItem(color: .yellow.opacity(0.85), label: "Mixed")
            Spacer()
        }
        .padding(.top, 4)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shared Components

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
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private func chartCard<Content: View>(
        title: String,
        symbol: String,
        tint: Color,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(14)
        .background(cardBackground)
    }

    private func emptyStateCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .accessibilityIdentifier("summary-empty-state")
    }

    private var advancedSummaryLink: some View {
        NavigationLink {
            AdvancedSummaryView(
                viewModel: viewModel,
                initialSelection: .range(selectedTrendsRange.asSummaryTimeRange)
            )
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("More Information")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Detailed feeds, sleep, nappies, and activity for a range or specific day.")
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(.thinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 14, y: 8)
    }

}

// MARK: - TrendsTimeRange bridge

private extension TrendsTimeRange {
    var asSummaryTimeRange: SummaryTimeRange {
        switch self {
        case .sevenDays: .sevenDays
        case .thirtyDays: .thirtyDays
        case .allTime: .allTime
        }
    }
}

// MARK: - Previews

#Preview("With Data") {
    NavigationStack {
        SummaryScreenView(viewModel: SummaryScreenPreviewFactory.summaryViewModel)
    }
}

#Preview("Empty") {
    NavigationStack {
        SummaryScreenView(viewModel: SummaryViewModel(events: []))
    }
}
