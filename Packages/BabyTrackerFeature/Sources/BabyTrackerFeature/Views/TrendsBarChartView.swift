import Charts
import SwiftUI

/// Bar chart for a single Trends metric series (e.g. bottle mL, breast sessions, sleep minutes).
///
/// Owns its own selection state so that touching a bar shows a callout with the
/// value at that day and dims unselected bars.
struct TrendsBarChartView: View {
    let points: [(String, Int)]
    let tint: Color
    var valueFormatter: ((Int) -> String)? = nil

    @State private var selectedKey: String?

    private var isDense: Bool { points.count > 14 }

    var body: some View {
        Chart {
            ForEach(chartPoints) { point in
                BarMark(
                    x: .value("Day", point.domainKey),
                    y: .value("Value", point.value)
                )
                // Dim unselected bars when a selection is active.
                .foregroundStyle(
                    selectedKey == nil || selectedKey == point.domainKey
                        ? tint
                        : tint.opacity(0.3)
                )
                .annotation(position: .top, spacing: 2) {
                    // Hide static labels when a selection callout is showing.
                    if !isDense && point.value > 0 && selectedPoint == nil {
                        Text(valueFormatter?(point.value) ?? "\(point.value)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let selectedPoint {
                RuleMark(x: .value("Selected", selectedPoint.domainKey))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        Text(valueFormatter?(selectedPoint.value) ?? "\(selectedPoint.value)")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6))
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 4)) {
                    if let key = value.as(String.self), let point = chartPoints.first(where: { $0.domainKey == key }) {
                        Text(point.label)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let axisValue = value.as(Int.self) {
                        Text(valueFormatter?(axisValue) ?? "\(axisValue)")
                    }
                }
            }
        }
        .chartYScale(domain: 0...yAxisUpperBound)
        .chartLegend(.hidden)
        .chartXSelection(value: $selectedKey)
        .frame(height: isDense ? 100 : 120)
    }

    private var chartPoints: [BarPoint] {
        TrendsChartPoint.makePoints(from: points)
    }

    private var selectedPoint: BarPoint? {
        guard let selectedKey else { return nil }
        return chartPoints.first(where: { $0.domainKey == selectedKey })
    }

    private var xAxisValues: [String] {
        TrendsChartLayout.axisValues(count: chartPoints.count, desiredVisibleCount: isDense ? 5 : chartPoints.count)
            .map { chartPoints[$0].domainKey }
    }

    private var yAxisUpperBound: Int {
        TrendsChartLayout.yDomainUpperBound(for: points.map(\.1))
    }
}

private typealias BarPoint = TrendsChartPoint

#Preview("Standard") {
    TrendsBarChartView(
        points: [("Mon", 140), ("Tue", 90), ("Wed", 170), ("Thu", 120), ("Fri", 80)],
        tint: .blue
    )
    .padding()
}

#Preview("Zero state") {
    TrendsBarChartView(points: [("Mon", 0), ("Tue", 0), ("Wed", 0)], tint: .pink)
        .padding()
}
