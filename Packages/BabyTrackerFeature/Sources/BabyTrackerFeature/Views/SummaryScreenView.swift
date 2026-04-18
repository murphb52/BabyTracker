import BabyTrackerDomain
import Charts
import SwiftUI

private enum SummaryTab: String, CaseIterable {
    case today = "Today"
    case trends = "Trends"
}

private protocol TodayChartFilter: CaseIterable, Identifiable, Hashable {
    var label: String { get }
}

private enum TodayNappyChartFilter: String, TodayChartFilter {
    case all
    case pee
    case poo
    case mixed
    case peeIncludingMixed
    case pooIncludingMixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .pee: "Pee"
        case .poo: "Poo"
        case .mixed: "Mixed"
        case .peeIncludingMixed: "Pee incl. mixed"
        case .pooIncludingMixed: "Poo incl. mixed"
        }
    }

    func series(from data: TodayChartData) -> HourlyCumulativeSeries {
        switch self {
        case .all: data.nappy
        case .pee: data.nappyPee
        case .poo: data.nappyPoo
        case .mixed: data.nappyMixed
        case .peeIncludingMixed: data.nappyPeeIncludingMixed
        case .pooIncludingMixed: data.nappyPooIncludingMixed
        }
    }
}

private enum TodayBottleChartFilter: String, TodayChartFilter {
    case all
    case formula
    case breastMilk
    case mixed
    case formulaIncludingMixed
    case breastMilkIncludingMixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .formula: "Formula"
        case .breastMilk: "Breast milk"
        case .mixed: "Mixed milk"
        case .formulaIncludingMixed: "Formula incl. mixed"
        case .breastMilkIncludingMixed: "Breast milk incl. mixed"
        }
    }

    func series(from data: TodayChartData) -> HourlyCumulativeSeries {
        switch self {
        case .all: data.bottle
        case .formula: data.bottleFormula
        case .breastMilk: data.bottleBreastMilk
        case .mixed: data.bottleMixed
        case .formulaIncludingMixed: data.bottleFormulaIncludingMixed
        case .breastMilkIncludingMixed: data.bottleBreastMilkIncludingMixed
        }
    }
}

private enum TrendsNappyChartFilter: String, TodayChartFilter {
    case all
    case wet
    case dirty
    case mixed
    case dry
    case wetIncludingMixed
    case dirtyIncludingMixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .wet: "Wet"
        case .dirty: "Dirty"
        case .mixed: "Mixed"
        case .dry: "Dry"
        case .wetIncludingMixed: "Wet incl. mixed"
        case .dirtyIncludingMixed: "Dirty incl. mixed"
        }
    }

    var tint: Color {
        switch self {
        case .all, .dry: .green
        case .wet, .wetIncludingMixed: .blue
        case .dirty, .dirtyIncludingMixed: .brown
        case .mixed: .yellow
        }
    }

    func points(from data: [DailyNappyData]) -> [(String, Int)] {
        data.map { day in
            (day.label, count(for: day))
        }
    }

    func averageText(from data: [DailyNappyData]) -> String? {
        guard let average = averageValue(from: data) else { return nil }
        return "Avg \(average)/day"
    }

    func averageValue(from data: [DailyNappyData]) -> Int? {
        let values = data.map(count(for:))
        let nonZeroValues = values.filter { $0 > 0 }
        guard !nonZeroValues.isEmpty else { return nil }
        return Int((Double(nonZeroValues.reduce(0, +)) / Double(nonZeroValues.count)).rounded())
    }

    private func count(for day: DailyNappyData) -> Int {
        switch self {
        case .all: day.totalCount
        case .wet: day.wetCount
        case .dirty: day.dirtyCount
        case .mixed: day.mixedCount
        case .dry: day.dryCount
        case .wetIncludingMixed: day.wetCount + day.mixedCount
        case .dirtyIncludingMixed: day.dirtyCount + day.mixedCount
        }
    }
}

private enum TrendsBottleChartFilter: String, TodayChartFilter {
    case all
    case formula
    case breastMilk
    case mixed
    case formulaIncludingMixed
    case breastMilkIncludingMixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: "All"
        case .formula: "Formula"
        case .breastMilk: "Breast milk"
        case .mixed: "Mixed milk"
        case .formulaIncludingMixed: "Formula incl. mixed"
        case .breastMilkIncludingMixed: "Breast milk incl. mixed"
        }
    }

    var tint: Color {
        switch self {
        case .all, .formula, .formulaIncludingMixed: .blue
        case .breastMilk, .breastMilkIncludingMixed: .cyan
        case .mixed: .mint
        }
    }

    func points(from data: [DailyBottleData]) -> [(String, Int)] {
        data.map { day in
            (day.label, value(for: day))
        }
    }

    func averageText(from data: [DailyBottleData], unit: FeedVolumeUnit) -> String? {
        guard let average = averageValue(from: data) else { return nil }
        return "Avg \(FeedVolumePresentation.perDayText(for: average, unit: unit))"
    }

    func averageValue(from data: [DailyBottleData]) -> Int? {
        let values = data.map(value(for:))
        let nonZeroValues = values.filter { $0 > 0 }
        guard !nonZeroValues.isEmpty else { return nil }
        return Int((Double(nonZeroValues.reduce(0, +)) / Double(nonZeroValues.count)).rounded())
    }

    private func value(for day: DailyBottleData) -> Int {
        switch self {
        case .all: day.totalMilliliters
        case .formula: day.formulaMilliliters
        case .breastMilk: day.breastMilkMilliliters
        case .mixed: day.mixedMilliliters
        case .formulaIncludingMixed: day.formulaMilliliters + day.mixedMilliliters
        case .breastMilkIncludingMixed: day.breastMilkMilliliters + day.mixedMilliliters
        }
    }
}

public struct SummaryScreenView: View {
    let viewModel: SummaryViewModel

    @State private var selectedTab: SummaryTab = .today
    @State private var selectedDate: Date = .now
    @State private var showDatePicker: Bool = false
    @State private var selectedTrendsRange: TrendsTimeRange = .sevenDays
    @State private var selectedNappyFilter: TodayNappyChartFilter = .all
    @State private var selectedBottleFilter: TodayBottleChartFilter = .all
    @State private var selectedTrendsNappyFilter: TrendsNappyChartFilter = .all
    @State private var selectedTrendsBottleFilter: TrendsBottleChartFilter = .all
    @Namespace private var advancedSummaryNamespace

    private var isSelectedDateToday: Bool {
        Calendar.autoupdatingCurrent.isDateInToday(selectedDate)
    }

    private var dateLabel: String {
        if isSelectedDateToday {
            return "Today"
        } else if Calendar.autoupdatingCurrent.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: selectedDate)
        }
    }

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
    }

    // MARK: - Today Tab

    private var todayTabContent: some View {
        let data = TodaySummaryCalculator.makeData(
            from: viewModel.events,
            day: selectedDate
        )

        return Group {
            if viewModel.events.isEmpty {
                emptyStateCard(
                    title: viewModel.emptyStateTitle,
                    message: viewModel.emptyStateMessage
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    dateNavigationRow
                    sleepSectionCard(data: data)
                    bottleSectionCard(data: data)
                    breastSectionCard(data: data)
                    nappySectionCard(data: data)
                    advancedSummaryLink
                    loggingStreakRow(data: data)
                }
            }
        }
    }

    // MARK: - Date Navigation

    private var dateNavigationRow: some View {
        HStack(spacing: 0) {
            Button {
                let calendar = Calendar.autoupdatingCurrent
                selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 36)
                    .contentShape(Rectangle())
            }

            Spacer(minLength: 0)

            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.subheadline)
                    Text(dateLabel)
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.primary)
            }
            .popover(isPresented: $showDatePicker) {
                VStack(spacing: 0) {
                    DatePicker(
                        "Select date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()

                    Button("Done") { showDatePicker = false }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
                .frame(width: 340, height: 420)
                .presentationCompactAdaptation(.popover)
            }

            Spacer(minLength: 0)

            Button {
                let calendar = Calendar.autoupdatingCurrent
                if let next = calendar.date(byAdding: .day, value: 1, to: selectedDate), next <= .now {
                    selectedDate = next
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 36)
                    .contentShape(Rectangle())
            }
            .disabled(isSelectedDateToday)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(cardBackground)
    }

    // MARK: - Today Section Cards

    private func bottleSectionCard(data: TodaySummaryData) -> some View {
        let preferredUnit = viewModel.preferredFeedVolumeUnit

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Label("Bottle", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)

                Spacer(minLength: 0)

                todayFilterPicker(
                    title: "Bottle chart filter",
                    selection: $selectedBottleFilter
                )
            }

            Text(FeedVolumePresentation.amountText(for: data.bottleTotalMilliliters, unit: preferredUnit))
                .font(.title3.weight(.bold))

            if data.bottleCount > 0 {
                bottleBreakdownRow(data: data)
            }

            // Feed timing
            bottleFeedTimingRow(data: data)

            CumulativeLineChartView(
                series: selectedBottleFilter.series(from: data.chartData),
                tint: .blue,
                isToday: isSelectedDateToday,
                valueFormatter: { value in
                    FeedVolumePresentation.amountText(for: value, unit: preferredUnit)
                }
            )
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
    }

    private func bottleBreakdownRow(data: TodaySummaryData) -> some View {
        let preferredUnit = viewModel.preferredFeedVolumeUnit
        let parts: [String] = [
            data.formulaMilliliters > 0
                ? "Formula \(FeedVolumePresentation.amountText(for: data.formulaMilliliters, unit: preferredUnit))"
                : nil,
            data.breastMilkMilliliters > 0
                ? "Breast milk \(FeedVolumePresentation.amountText(for: data.breastMilkMilliliters, unit: preferredUnit))"
                : nil,
            data.mixedMilkMilliliters > 0
                ? "Mixed \(FeedVolumePresentation.amountText(for: data.mixedMilkMilliliters, unit: preferredUnit))"
                : nil,
        ].compactMap { $0 }

        return Text(parts.isEmpty ? "\(data.bottleCount) feed\(data.bottleCount == 1 ? "" : "s")" : parts.joined(separator: " • "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func bottleFeedTimingRow(data: TodaySummaryData) -> some View {
        var parts: [String] = []
        if isSelectedDateToday, let mins = data.minutesSinceLastFeed {
            parts.append("Last \(DurationText.short(minutes: mins)) ago")
        }
        if let avg = data.averageFeedIntervalMinutes {
            parts.append("Avg interval \(DurationText.short(minutes: avg))")
        }
        let noFeedsText = isSelectedDateToday ? "No bottle feeds today" : "No bottle feeds on this day"
        guard !parts.isEmpty else { return Text(noFeedsText).font(.caption).foregroundStyle(.secondary) }
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
                Text(isSelectedDateToday ? "No breast feeds today" : "No breast feeds on this day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: data.chartData.breast, tint: .pink, isToday: isSelectedDateToday)
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
                Text(isSelectedDateToday ? "No sleep logged today" : "No sleep logged on this day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: data.chartData.sleep, tint: .indigo, isToday: isSelectedDateToday)
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
            if isSelectedDateToday, let mins = data.minutesSinceLastSleep {
                Text("Last sleep \(DurationText.short(minutes: mins)) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func nappySectionCard(data: TodaySummaryData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Label("Nappies", systemImage: "checklist.checked")
                    .font(.headline)
                    .foregroundStyle(.green)

                Spacer(minLength: 0)

                todayFilterPicker(
                    title: "Nappy chart filter",
                    selection: $selectedNappyFilter
                )
            }

            Text("\(data.totalNappies)")
                .font(.title3.weight(.bold))

            if data.totalNappies > 0 {
                nappyBreakdownRow(data: data)
            } else {
                Text(isSelectedDateToday ? "No nappy changes today" : "No nappy changes on this day")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            CumulativeLineChartView(series: selectedNappyFilter.series(from: data.chartData), tint: .green, isToday: isSelectedDateToday)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardBackground)
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
                sleepChartCard(data: data)
                bottleChartCard(data: data)
                breastChartCard(data: data)
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
        let preferredUnit = viewModel.preferredFeedVolumeUnit
        let points = selectedTrendsBottleFilter.points(from: data.dailyBottle)
        let avgText = selectedTrendsBottleFilter.averageText(from: data.dailyBottle, unit: preferredUnit)
        let avgValue = selectedTrendsBottleFilter.averageValue(from: data.dailyBottle)

        return chartCard(
            title: "Bottle Feeds",
            symbol: "drop.fill",
            tint: .blue,
            subtitle: avgText ?? "No bottle feeds in this period",
            trailingControl: {
                todayFilterPicker(
                    title: "Trends bottle chart filter",
                    selection: $selectedTrendsBottleFilter
                )
            }
        ) {
            TrendsBarChartView(
                points: points,
                tint: selectedTrendsBottleFilter.tint,
                valueFormatter: { value in
                    FeedVolumePresentation.amountText(for: value, unit: preferredUnit)
                },
                averageValue: avgValue
            )
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
            TrendsBarChartView(
                points: points,
                tint: .pink,
                averageValue: data.avgDailyBreastFeedSessions
            )
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
            TrendsBarChartView(
                points: points,
                tint: .indigo,
                valueFormatter: { DurationText.short(minutes: $0) },
                averageValue: data.avgDailySleepMinutes
            )
        }
    }

    private func nappyChartCard(data: TrendsSummaryData) -> some View {
        let avgText = selectedTrendsNappyFilter.averageText(from: data.dailyNappy)
        let avgValue = selectedTrendsNappyFilter.averageValue(from: data.dailyNappy)

        return chartCard(
            title: "Nappies",
            symbol: "checklist.checked",
            tint: .green,
            subtitle: avgText ?? "No nappy changes in this period",
            trailingControl: {
                todayFilterPicker(
                    title: "Trends nappy chart filter",
                    selection: $selectedTrendsNappyFilter
                )
            }
        ) {
            if selectedTrendsNappyFilter == .all {
                TrendsNappyChartView(data: data.dailyNappy, averageValue: avgValue)
            } else {
                TrendsBarChartView(
                    points: selectedTrendsNappyFilter.points(from: data.dailyNappy),
                    tint: selectedTrendsNappyFilter.tint,
                    averageValue: avgValue
                )
            }
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
        chartCard(
            title: title,
            symbol: symbol,
            tint: tint,
            subtitle: subtitle,
            trailingControl: { EmptyView() },
            content: content
        )
    }

    private func chartCard<Content: View, TrailingControl: View>(
        title: String,
        symbol: String,
        tint: Color,
        subtitle: String,
        @ViewBuilder trailingControl: () -> TrailingControl,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundStyle(tint)

                Spacer(minLength: 0)

                trailingControl()
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 6)

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
                initialSelection: isSelectedDateToday
                    ? .range(selectedTrendsRange.asSummaryTimeRange)
                    : .day(selectedDate)
            )
            .navigationTransition(.zoom(sourceID: "advancedSummary", in: advancedSummaryNamespace))
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
        .matchedTransitionSource(id: "advancedSummary", in: advancedSummaryNamespace)
    }

    private func todayFilterPicker<Filter: TodayChartFilter>(
        title: String,
        selection: Binding<Filter>
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(Array(Filter.allCases)) { filter in
                Text(filter.label).tag(filter)
            }
        }
        .pickerStyle(.menu)
        .font(.caption)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
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

#Preview("Today Filters") {
    NavigationStack {
        SummaryScreenView(viewModel: SummaryScreenPreviewFactory.summaryViewModel)
    }
}
