import Charts
import SwiftUI

/// A two-line overlay chart for the Today tab.
///
/// Renders a solid colored line for today's cumulative total by hour (stopping
/// at the current hour with a "Now" callout) and a dashed secondary line for the
/// 7-day average cumulative total. Both axes are handled natively by Swift Charts.
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
                    x: .value("Hour", point.date),
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
                    x: .value("Hour", point.date),
                    y: .value("Today", point.value),
                    series: .value("Series", "today")
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }

            // "Now" indicator — vertical rule at the current hour with a callout
            RuleMark(x: .value("Now", currentDate))
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
        .chartXScale(domain: startOfDay...endOfDay)
        .chartYScale(domain: 0...maxValue)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        // Extra top inset reserves space for the "Now" annotation inside the chart frame
        // so it doesn't overflow into the card content above.
        .chartPlotStyle { plotArea in
            plotArea.padding(.top, 28)
        }
        .chartLegend(.hidden)
        .frame(height: 120)
        .accessibilityLabel("Cumulative chart showing today's total versus the 7-day average by hour")
    }

    // MARK: - Private

    private var calendar: Calendar { .current }

    private var startOfDay: Date {
        calendar.startOfDay(for: Date())
    }

    private var endOfDay: Date {
        // Anchor the x-axis to the last hour of today (hour 23)
        calendar.date(byAdding: .hour, value: 23, to: startOfDay)!
    }

    private var currentDate: Date {
        let hour = calendar.component(.hour, from: Date())
        return calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
    }

    private var todayPoints: [HourPoint] {
        let currentHour = calendar.component(.hour, from: Date())
        return series.todayCumulative
            .enumerated()
            .prefix(currentHour + 1)
            .compactMap { hour, value in
                calendar.date(byAdding: .hour, value: hour, to: startOfDay)
                    .map { HourPoint(id: hour, date: $0, value: value) }
            }
    }

    private var averagePoints: [HourPoint] {
        series.averageCumulative
            .enumerated()
            .compactMap { hour, value in
                calendar.date(byAdding: .hour, value: hour, to: startOfDay)
                    .map { HourPoint(id: hour, date: $0, value: value) }
            }
    }

    private var maxValue: Int {
        max(1, (series.todayCumulative + series.averageCumulative).max() ?? 1)
    }
}

// MARK: - Supporting types

private struct HourPoint: Identifiable {
    let id: Int    // hour index (0–23) — unique within each ForEach block
    let date: Date
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
