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
    let isToday: Bool
    let valueFormatter: (Int) -> String

    @State private var selectedHour: Int?

    init(
        series: HourlyCumulativeSeries,
        tint: Color,
        isToday: Bool = true,
        valueFormatter: @escaping (Int) -> String = { "\($0)" }
    ) {
        self.series = series
        self.tint = tint
        self.isToday = isToday
        self.valueFormatter = valueFormatter
    }

    var body: some View {
        Chart {
            // 7-day average — dashed, secondary, full 24 hours; only shown while interacting.
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

            // "Now" indicator — only shown for today; selection callout renders on top due to mark order.
            if isToday {
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

            // Selection indicator — rendered after "Now" so it draws on top.
            if let hour = selectedHour, hour >= 0, hour < 24 {
                RuleMark(x: .value("Selected", hour))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        selectionCallout(for: hour)
                    }
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
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let axisValue = value.as(Int.self) {
                        Text(valueFormatter(axisValue))
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXSelection(value: $selectedHour)
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
        let hourLimit = isToday ? currentHour + 1 : 24
        return series.todayCumulative
            .enumerated()
            .prefix(hourLimit)
            .map { HourPoint(id: $0, hour: $0, value: $1) }
    }

    private var averagePoints: [HourPoint] {
        series.averageCumulative.enumerated().map { HourPoint(id: $0, hour: $0, value: $1) }
    }

    private var maxValue: Int {
        max(1, (series.todayCumulative + series.averageCumulative).max() ?? 1)
    }

    private func selectionCallout(for hour: Int) -> some View {
        let todayVal = series.todayCumulative[hour]
        let avgVal = series.averageCumulative[hour]
        return VStack(alignment: .leading, spacing: 2) {
            if !isToday || hour <= currentHour {
                Text("Today: \(valueFormatter(todayVal))").foregroundStyle(tint)
            }
            Text("Avg: \(valueFormatter(avgVal))").foregroundStyle(.secondary)
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
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
        tint: .blue,
        valueFormatter: { "\($0)" }
    )
    .padding()
}

#Preview("Zero state") {
    CumulativeLineChartView(series: .zero, tint: .pink, valueFormatter: { "\($0)" })
        .padding()
}
