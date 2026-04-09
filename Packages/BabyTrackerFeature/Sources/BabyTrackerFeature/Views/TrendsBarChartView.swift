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

    @State private var selectedLabel: String?

    private var isDense: Bool { points.count > 14 }

    var body: some View {
        Chart {
            ForEach(chartPoints) { point in
                BarMark(
                    x: .value("Date", point.label),
                    y: .value("Value", point.value)
                )
                // Dim unselected bars when a selection is active.
                .foregroundStyle(
                    selectedLabel == nil || selectedLabel == point.label
                        ? tint
                        : tint.opacity(0.3)
                )
                .annotation(position: .top, spacing: 2) {
                    // Hide static labels when a selection callout is showing.
                    if !isDense && point.value > 0 && selectedLabel == nil {
                        Text(valueFormatter?(point.value) ?? "\(point.value)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let label = selectedLabel, let match = points.first(where: { $0.0 == label }) {
                RuleMark(x: .value("Selected", label))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        Text(valueFormatter?(match.1) ?? "\(match.1)")
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
            }
        }
        .chartXAxis {
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
        .chartXSelection(value: $selectedLabel)
        .frame(height: isDense ? 100 : 120)
    }

    private var chartPoints: [BarPoint] {
        points.map { BarPoint(id: $0.0, label: $0.0, value: $0.1) }
    }
}

private struct BarPoint: Identifiable {
    let id: String
    let label: String
    let value: Int
}
