import Charts
import BabyTrackerDomain
import SwiftUI

/// Two animated chart cards used on the "Spot the patterns" onboarding page.
///
/// Each card fades in and slides up one after the other. Once both cards have
/// settled, the chart lines draw in left to right using a horizontal clip mask —
/// sleep first, then bottle feed.
struct OnboardingChartsDemoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sleepCardVisible = false
    @State private var bottleCardVisible = false
    @State private var sleepProgress: CGFloat = 0
    @State private var bottleProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            chartCard(
                title: "Sleep",
                systemImage: BabyEventStyle.systemImage(for: .sleep),
                tint: Color(.systemIndigo),
                series: Self.sleepSeries,
                progress: sleepProgress,
                valueFormatter: { "\($0) min" }
            )
            .opacity(sleepCardVisible ? 1 : 0)
            .offset(y: sleepCardVisible ? 0 : 20)
            .animation(
                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                value: sleepCardVisible
            )

            chartCard(
                title: "Bottle Feed",
                systemImage: BabyEventStyle.systemImage(for: .bottleFeed),
                tint: Color.blue,
                series: Self.bottleSeries,
                progress: bottleProgress,
                valueFormatter: { "\($0) mL" }
            )
            .opacity(bottleCardVisible ? 1 : 0)
            .offset(y: bottleCardVisible ? 0 : 20)
            .animation(
                reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8),
                value: bottleCardVisible
            )
        }
        .onAppear {
            guard !reduceMotion else {
                sleepCardVisible = true
                bottleCardVisible = true
                sleepProgress = 1
                bottleProgress = 1
                return
            }
            Task { @MainActor in
                // Wait for the page slide-in to settle
                try? await Task.sleep(for: .milliseconds(420))
                sleepCardVisible = true
                // Stagger the second card in
                try? await Task.sleep(for: .milliseconds(180))
                bottleCardVisible = true
                // Wait for the bottle card spring to land before drawing charts
                try? await Task.sleep(for: .milliseconds(500))
                // Draw sleep line left to right
                withAnimation(.easeInOut(duration: 1.3)) {
                    sleepProgress = 1
                }
                // Start bottle halfway through the sleep draw so the two charts overlap.
                try? await Task.sleep(for: .milliseconds(650))
                // Draw bottle line left to right
                withAnimation(.easeInOut(duration: 1.3)) {
                    bottleProgress = 1
                }
            }
        }
    }

    // MARK: - Chart card

    private func chartCard(
        title: String,
        systemImage: String,
        tint: Color,
        series: HourlyCumulativeSeries,
        progress: CGFloat,
        valueFormatter: @escaping (Int) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            demoChart(series: series, tint: tint)
                // Horizontal clip mask: reveals the chart left-to-right as progress goes 0→1.
                .mask {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            Color.black
                                .frame(width: geo.size.width * progress)
                            Color.clear
                        }
                    }
                }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Chart

    private func demoChart(series: HourlyCumulativeSeries, tint: Color) -> some View {
        let maxValue = max(1, (series.todayCumulative + series.averageCumulative).max() ?? 1)
        let avgPoints = series.averageCumulative.enumerated().map { DemoHourPoint(id: $0, hour: $0, value: $1) }
        let todayPoints = series.todayCumulative.enumerated().map { DemoHourPoint(id: $0, hour: $0, value: $1) }

        return Chart {
            // 7-day average — dashed, secondary
            ForEach(avgPoints) { point in
                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Avg", point.value),
                    series: .value("Series", "average")
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.secondary.opacity(0.3))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 6]))
            }
            // Today — area fill behind solid line
            ForEach(todayPoints) { point in
                AreaMark(
                    x: .value("Hour", point.hour),
                    y: .value("Today", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(tint.opacity(0.12))
            }
            ForEach(todayPoints) { point in
                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("Today", point.value),
                    series: .value("Series", "today")
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .chartXScale(domain: 0...23)
        .chartYScale(domain: 0...maxValue)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18]) { value in
                AxisGridLine()
                AxisValueLabel {
                    switch value.as(Int.self) {
                    case 0:  Text("12a")
                    case 6:  Text("6a")
                    case 12: Text("12p")
                    case 18: Text("6p")
                    default: EmptyView()
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .allowsHitTesting(false)
        .frame(height: 80)
        .padding(.top, 4)
    }

    // MARK: - Supporting types

    private struct DemoHourPoint: Identifiable {
        let id: Int
        let hour: Int
        let value: Int
    }

    // MARK: - Sample data

    /// Cumulative sleep minutes by hour.
    /// ~5h night sleep, 1h morning nap around 9am, 1.5h afternoon nap around 1pm, 1h bedtime around 7pm.
    private static let sleepSeries = HourlyCumulativeSeries(
        todayCumulative: [
            60, 120, 180, 240, 300, 300, 300, 300, 300, // 12a–8a (hours 0–8, night sleep ends ~5am)
            360, 360, 360, 360,                          // 9a–12p (hours 9–12, morning nap at 9am)
            420, 480, 480,                               // 1p–3p  (hours 13–15, afternoon nap)
            480, 480, 480,                               // 4p–6p  (hours 16–18)
            540, 540, 540, 540, 540,                     // 7p–11p (hours 19–23, bedtime at 7pm)
        ],
        averageCumulative: [
            55, 110, 165, 220, 275, 275, 275, 275, 275,
            335, 335, 335, 335,
            395, 455, 455,
            455, 455, 455,
            515, 515, 515, 515, 515,
        ]
    )

    /// Cumulative bottle feed volume (mL) by hour.
    /// Four feeds: 6am 150mL, 10am 150mL, 2pm 150mL, 5:30pm 150mL.
    private static let bottleSeries = HourlyCumulativeSeries(
        todayCumulative: [
            0, 0, 0, 0, 0, 0,            // 12a–5a
            150, 150, 150, 150,           // 6a–9a
            300, 300, 300, 300,           // 10a–1p
            450, 450, 450,               // 2p–4p
            600, 600, 600, 600, 600, 600, 600, // 5p–11p
        ],
        averageCumulative: [
            0, 0, 0, 0, 0, 0,
            130, 130, 130, 130,
            260, 260, 260, 260,
            390, 390, 390,
            520, 520, 520, 520, 520, 520, 520,
        ]
    )
}

#Preview {
    OnboardingChartsDemoView()
        .padding(.horizontal, 24)
}
