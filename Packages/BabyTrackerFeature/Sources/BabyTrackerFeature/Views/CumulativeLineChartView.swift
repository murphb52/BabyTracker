import Charts
import SwiftUI

/// A two-line overlay chart for the Today tab.
///
/// Renders a solid colored line for today's cumulative total by hour (stopping
/// at the current hour with a "Now" callout) and a dashed secondary line for the
/// 7-day average cumulative total. The x-axis spans all 24 hours; the y-axis
/// auto-scales to the maximum of both series and is hidden because the chart is
/// used as visual context, not for precise value reading.
struct CumulativeLineChartView: View {
    let series: HourlyCumulativeSeries
    let tint: Color

    var body: some View {
        Chart {
            // 7-day average — dashed, secondary, full 24 hours
            // series: groups all 24 marks into one continuous line so the
            // dash pattern is applied across the whole series, not per segment.
            ForEach(averagePoints) { point in
                LineMark(
                    x: .value("Hour", point.hour),
                    y: .value("7-Day Avg", point.value),
                    series: .value("Series", "average")
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(Color.secondary.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
            }

            // Today — solid, tinted, stops at the current hour
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

            // "Now" indicator — vertical rule at the current hour with a callout
            RuleMark(x: .value("Now", currentHour))
                .foregroundStyle(tint.opacity(0.25))
                .lineStyle(StrokeStyle(lineWidth: 1))
                .annotation(position: .top, alignment: .center, spacing: 4) {
                    Text("Now")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(tint)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(tint.opacity(0.12), in: Capsule())
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
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .frame(height: 100)
        // Space above the chart so the "Now" annotation can float without
        // overlapping the card content above it.
        .padding(.top, 24)
        .accessibilityLabel("Cumulative chart showing today's total versus the 7-day average by hour")
    }

    // MARK: - Private

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }

    private var todayPoints: [HourPoint] {
        series.todayCumulative
            .enumerated()
            .prefix(currentHour + 1)
            .map { HourPoint(id: $0, hour: $0, value: $1) }
    }

    private var averagePoints: [HourPoint] {
        series.averageCumulative.enumerated().map { HourPoint(id: $0, hour: $0, value: $1) }
    }

    private var maxValue: Int {
        max(1, (series.todayCumulative + series.averageCumulative).max() ?? 1)
    }
}

// MARK: - Supporting types

private struct HourPoint: Identifiable {
    // hour (0–23) is unique within each ForEach block
    let id: Int
    let hour: Int
    let value: Int
}

// MARK: - Preview

#Preview("With data") {
    let rising = [0, 0, 0, 0, 0, 0, 0, 100, 100, 200, 200, 200, 350, 350, 500, 500, 500, 600, 600, 600, 600, 600, 600, 600]
    let avg = [0, 0, 0, 0, 0, 0, 0, 80, 80, 160, 160, 240, 300, 300, 420, 420, 480, 540, 540, 540, 540, 540, 540, 540]
    CumulativeLineChartView(
        series: HourlyCumulativeSeries(todayCumulative: rising, averageCumulative: avg),
        tint: .blue
    )
    .padding()
}

#Preview("Zero state") {
    CumulativeLineChartView(series: .zero, tint: .pink)
        .padding()
}
