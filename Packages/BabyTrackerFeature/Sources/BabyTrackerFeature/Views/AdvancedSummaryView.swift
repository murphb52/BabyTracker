import SwiftUI

public struct AdvancedSummaryView: View {
    let viewModel: SummaryViewModel

    @State private var selection: AdvancedSummarySelection

    public init(
        viewModel: SummaryViewModel,
        initialSelection: AdvancedSummarySelection = .range(.today)
    ) {
        self.viewModel = viewModel
        _selection = State(initialValue: initialSelection)
    }

    public var body: some View {
        let viewState = AdvancedSummaryMetricsCalculator.makeViewState(
            from: viewModel.events,
            selection: selection
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                selectionCard

                if viewState.eventCount == 0 {
                    emptyState
                } else {
                    feedSection(viewState: viewState)
                    sleepSection(viewState: viewState)
                    nappySection(viewState: viewState)
                    activitySection(viewState: viewState)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("More Information")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Summary Type", selection: $selection.mode) {
                ForEach(AdvancedSummarySelectionMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if selection.mode == .range {
                Picker("Range", selection: $selection.range) {
                    ForEach(SummaryTimeRange.allCases) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            } else {
                DatePicker(
                    "Day",
                    selection: $selection.day,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
            }

            Text(selectionDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(cardBackground)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No summary data for this selection")
                .font(.headline)

            Text("Try a broader range or choose a different day to see detailed feed, sleep, nappy, and activity trends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func feedSection(viewState: AdvancedSummaryViewState) -> some View {
        sectionCard(title: "Feeds", tint: .blue, symbol: "drop.fill") {
            metricRow(title: "Total feeds", value: "\(viewState.totalFeeds)")
            metricRow(title: "Breast feeds", value: "\(viewState.breastFeedCount)")
            metricRow(title: "Bottle feeds", value: "\(viewState.bottleFeedCount)")
            metricRow(
                title: "Average bottle volume",
                value: viewState.averageBottleVolumeMilliliters.map { "\($0) mL" } ?? "No bottle feeds"
            )
        }
    }

    private func sleepSection(viewState: AdvancedSummaryViewState) -> some View {
        sectionCard(title: "Sleep", tint: .indigo, symbol: "moon.zzz.fill") {
            metricRow(title: "Completed sleeps", value: "\(viewState.completedSleepCount)")
            metricRow(title: "Total sleep", value: formatMinutes(viewState.totalSleepMinutes))
            metricRow(
                title: "Average sleep block",
                value: viewState.averageSleepBlockMinutes.map { formatMinutes($0) } ?? "No completed sleeps"
            )
            metricRow(
                title: "Longest sleep block",
                value: viewState.longestSleepBlockMinutes.map { formatMinutes($0) } ?? "No completed sleeps"
            )
        }
    }

    private func nappySection(viewState: AdvancedSummaryViewState) -> some View {
        sectionCard(title: "Nappies", tint: .green, symbol: "checklist.checked") {
            metricRow(title: "Total changes", value: "\(viewState.totalNappies)")
            metricRow(title: "Wet", value: "\(viewState.wetNappyCount)")
            metricRow(title: "Dirty", value: "\(viewState.dirtyNappyCount)")
            metricRow(title: "Mixed", value: "\(viewState.mixedNappyCount)")
            metricRow(title: "Dry", value: "\(viewState.dryNappyCount)")
        }
    }

    private func activitySection(viewState: AdvancedSummaryViewState) -> some View {
        sectionCard(title: "Activity", tint: .orange, symbol: "flame.fill") {
            metricRow(title: "Total events", value: "\(viewState.eventCount)")
            metricRow(
                title: "Busiest hour",
                value: viewState.busiestHourLabel.map { "\($0) (\(viewState.busiestHourCount))" } ?? "No activity"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(selection.mode == .day ? "Activity by Hour" : "Daily Activity")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                activityChart(viewState: viewState)
            }
            .padding(.top, 6)
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        tint: Color,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(tint)

            content()
        }
        .padding(16)
        .background(cardBackground)
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func activityChart(viewState: AdvancedSummaryViewState) -> some View {
        let points: [(String, Int)] = selection.mode == .day
            ? viewState.hourlyActivityCounts
                .filter { $0.count > 0 }
                .map { ($0.label, $0.count) }
            : viewState.dailyActivityCounts.map { ($0.label, $0.count) }

        return barChart(points: points.isEmpty ? [("None", 0)] : points)
    }

    private func barChart(points: [(String, Int)]) -> some View {
        let maxValue = max(1, points.map(\.1).max() ?? 0)

        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.orange.gradient)
                        .frame(height: max(6, (CGFloat(point.1) / CGFloat(maxValue)) * 100))

                    Text(point.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .bottom)
    }

    private var selectionDescription: String {
        switch selection.mode {
        case .range:
            switch selection.range {
            case .today:
                return "Detailed metrics for today."
            case .sevenDays:
                return "Detailed metrics for the last 7 days."
            case .thirtyDays:
                return "Detailed metrics for the last 30 days."
            case .allTime:
                return "Detailed metrics across all logged events."
            }
        case .day:
            return "Detailed metrics for \(selection.day.formatted(date: .abbreviated, time: .omitted))."
        }
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

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes)m"
        }

        return "\(hours)h \(remainingMinutes)m"
    }
}

#Preview {
    NavigationStack {
        AdvancedSummaryView(
            viewModel: SummaryScreenPreviewFactory.summaryViewModel,
            initialSelection: .range(.sevenDays)
        )
    }
}
