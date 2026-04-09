import BabyTrackerDomain
import Charts
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

        return Group {
            if viewModel.events.isEmpty {
                emptyStateCard(
                    title: viewModel.emptyStateTitle,
                    message: viewModel.emptyStateMessage
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    bottleSectionCard(data: data)
                    breastSectionCard(data: data)
                    sleepSectionCard(data: data)
                    nappySectionCard(data: data)
                    advancedSummaryLink
                    loggingStreakRow(data: data)
                }
            }
        }
    }

    // MARK: - Today Section Cards

    private func bottleSectionCard(data: TodaySummaryData) -> some View {
        sectionCard(title: "Bottle", symbol: "drop.fill", tint: .blue) {
            // Primary metric
            Text(data.bottleCount == 0 ? "0 mL" : "\(data.bottleTotalMilliliters) mL")
                .font(.title3.weight(.bold))

            // Breakdown by milk type
            if data.bottleCount > 0 {
                bottleBreakdownRow(data: data)
            }

            // Feed timing
            bottleFeedTimingRow(data: data)

            CumulativeLineChartView(series: data.chartData.bottle, tint: .blue)
                .padding(.top, 4)
        }
    }

    private func bottleBreakdownRow(data: TodaySummaryData) -> some View {
        let parts: [String] = [
            data.formulaMilliliters > 0 ? "Formula \(data.formulaMilliliters) mL" : nil,
            data.breastMilkMilliliters > 0 ? "Breast milk \(data.breastMilkMilliliters) mL" : nil,
            data.mixedMilkMilliliters > 0 ? "Mixed \(data.mixedMilkMilliliters) mL" : nil,
        ].compactMap { $0 }

        return Text(parts.isEmpty ? "\(data.bottleCount) feed\(data.bottleCount == 1 ? "" : "s")" : parts.joined(separator: " • "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func bottleFeedTimingRow(data: TodaySummaryData) -> some View {
        let parts: [String] = [
            data.minutesSinceLastFeed.map { "Last \(DurationText.short(minutes: $0)) ago" },
            data.averageFeedIntervalMinutes.map { "Avg interval \(DurationText.short(minutes: $0))" },
        ].compactMap { $0 }

        guard !parts.isEmpty else { return Text("No bottle feeds today").font(.caption).foregroundStyle(.secondary) }
        return Text(parts.joined(separator: " • ")).font(.caption).foregroundStyle(.secondary)
    }

    private func breastSectionCard(data: TodaySummaryData) -> some View {
        sectionCard(title: "Breast", symbol: "heart.fill", tint: .pink) {
            Text(data.breastFeedCount == 0
                ? "0 sessions"
                : "\(data.breastFeedCount) session\(data.breastFeedCount == 1 ? "" : "s")")
                .font(.title3.weight(.bold))

            if data.breastFeedCount > 0 {
                breastMetricsRow(data: data)
            } else {
                Text("No breast feeds today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: data.chartData.breast, tint: .pink)
                .padding(.top, 4)
        }
    }

    private func breastMetricsRow(data: TodaySummaryData) -> some View {
        var parts = ["\(DurationText.short(minutes: data.breastFeedTotalMinutes)) total"]
        if let avg = data.averageBreastFeedMinutes {
            parts.append("avg \(DurationText.short(minutes: avg))")
        }
        return Text(parts.joined(separator: " • "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func sleepSectionCard(data: TodaySummaryData) -> some View {
        sectionCard(title: "Sleep", symbol: "moon.zzz.fill", tint: .indigo) {
            Text(data.totalSleepMinutes == 0 ? "0m" : DurationText.short(minutes: data.totalSleepMinutes))
                .font(.title3.weight(.bold))

            if data.totalSleepMinutes > 0 {
                sleepSessionMetricsRow(data: data)
                sleepTimingRow(data: data)
            } else {
                Text("No sleep logged today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: data.chartData.sleep, tint: .indigo)
                .padding(.top, 4)
        }
    }

    private func sleepSessionMetricsRow(data: TodaySummaryData) -> some View {
        let parts: [String] = [
            data.longestSleepBlockMinutes.map { "Longest \(DurationText.short(minutes: $0))" },
            data.shortestSleepBlockMinutes.map { "Shortest \(DurationText.short(minutes: $0))" },
            data.averageSleepBlockMinutes.map { "Avg \(DurationText.short(minutes: $0))" },
        ].compactMap { $0 }

        return Text(parts.joined(separator: " • "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func sleepTimingRow(data: TodaySummaryData) -> some View {
        Group {
            if let mins = data.minutesSinceLastSleep {
                Text("Last sleep \(DurationText.short(minutes: mins)) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func nappySectionCard(data: TodaySummaryData) -> some View {
        sectionCard(title: "Nappies", symbol: "checklist.checked", tint: .green) {
            Text("\(data.totalNappies)")
                .font(.title3.weight(.bold))

            if data.totalNappies > 0 {
                nappyBreakdownRow(data: data)
            } else {
                Text("No nappy changes today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: data.chartData.nappy, tint: .green)
                .padding(.top, 4)
        }
    }

    private func nappyBreakdownRow(data: TodaySummaryData) -> some View {
        let parts: [String] = [
            data.wetNappyCount > 0 ? "Wet: \(data.wetNappyCount)" : nil,
            data.dirtyNappyCount > 0 ? "Dirty: \(data.dirtyNappyCount)" : nil,
            data.mixedNappyCount > 0 ? "Mixed: \(data.mixedNappyCount)" : nil,
            data.dryNappyCount > 0 ? "Dry: \(data.dryNappyCount)" : nil,
        ].compactMap { $0 }

        return Text(parts.joined(separator: " • "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func loggingStreakRow(data: TodaySummaryData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.subheadline)
                .foregroundStyle(.orange)
                .frame(width: 24)

            Text("Logging streak")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text("\(data.loggingStreakDays) day\(data.loggingStreakDays == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
    }

    // MARK: - Shared section card container

    private func sectionCard<Content: View>(
        title: String,
        symbol: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
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
            symbol: "drop.fill",
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
        }
    }

    // MARK: - Chart Components

    /// Bar chart for a single metric series (bottle mL, breast sessions, sleep minutes).
    /// Shows value annotations above each bar for sparse ranges; relies on Swift Charts'
    /// automatic axis thinning for dense 30-day ranges.
    @ViewBuilder
    private func miniBarChart(
        points: [(String, Int)],
        tint: Color,
        valueFormatter: ((Int) -> String)? = nil
    ) -> some View {
        let isDense = points.count > 14
        let chartPoints = points.map { TrendsBarPoint(id: $0.0, label: $0.0, value: $0.1) }

        Chart(chartPoints) { point in
            BarMark(
                x: .value("Date", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(tint)
            .annotation(position: .top, spacing: 2) {
                if !isDense && point.value > 0 {
                    Text(valueFormatter?(point.value) ?? "\(point.value)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartXAxis {
            // desiredCount drives automatic label thinning — no manual sparseAxisLabels needed.
            AxisMarks(values: .automatic(desiredCount: isDense ? 5 : points.count)) { _ in
                AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .frame(height: isDense ? 100 : 120)
    }

    /// Stacked bar chart for nappy types (wet / dirty / mixed) per day.
    /// The chart generates its own legend, replacing the former manual legend view.
    @ViewBuilder
    private func stackedNappyChart(data: [DailyNappyData]) -> some View {
        let isDense = data.count > 14
        // Include all three types for every day (even when count is 0) so Swift Charts
        // establishes a consistent wet → dirty → mixed stacking order across all bars.
        let segments: [NappySegment] = data.flatMap { day in
            [
                NappySegment(id: "\(day.label)-wet",   label: day.label, type: "Wet",   count: day.wetCount),
                NappySegment(id: "\(day.label)-dirty", label: day.label, type: "Dirty", count: day.dirtyCount),
                NappySegment(id: "\(day.label)-mixed", label: day.label, type: "Mixed", count: day.mixedCount),
            ]
        }

        Chart(segments) { segment in
            BarMark(
                x: .value("Date", segment.label),
                y: .value("Count", segment.count)
            )
            .foregroundStyle(by: .value("Type", segment.type))
        }
        .chartForegroundStyleScale([
            "Wet":   Color.blue.opacity(0.6),
            "Dirty": Color.brown.opacity(0.75),
            "Mixed": Color.yellow.opacity(0.85),
        ])
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: isDense ? 5 : data.count)) { _ in
                AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 4))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(position: .bottom, alignment: .leading)
        .frame(height: isDense ? 120 : 140)
    }

    // MARK: - Chart Data Models

    private struct TrendsBarPoint: Identifiable {
        let id: String    // date label — unique within a chart dataset
        let label: String
        let value: Int
    }

    private struct NappySegment: Identifiable {
        let id: String    // "\(label)-\(type)" — unique within the flattened dataset
        let label: String
        let type: String  // "Wet", "Dirty", or "Mixed"
        let count: Int
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

#Preview("Trends 30 Days") {
    NavigationStack {
        SummaryScreenView(viewModel: SummaryScreenPreviewFactory.summaryViewModel)
    }
}
