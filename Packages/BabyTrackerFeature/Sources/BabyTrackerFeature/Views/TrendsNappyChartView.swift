import Charts
import SwiftUI

/// Stacked bar chart for nappy types (wet / dirty / mixed) per day.
///
/// Owns its own selection state so that touching a bar shows a breakdown callout
/// for that day. The chart generates its own legend.
struct TrendsNappyChartView: View {
    let data: [DailyNappyData]

    @State private var selectedLabel: String?

    private var isDense: Bool { data.count > 14 }

    var body: some View {
        Chart {
            // Include all three types for every day (even when count is 0) so Swift Charts
            // establishes a consistent wet → dirty → mixed stacking order across all bars.
            ForEach(segments) { segment in
                BarMark(
                    x: .value("Date", segment.label),
                    y: .value("Count", segment.count)
                )
                .foregroundStyle(by: .value("Type", segment.type))
                .opacity(selectedLabel == nil || selectedLabel == segment.label ? 1 : 0.3)
            }

            if let label = selectedLabel, let day = data.first(where: { $0.label == label }) {
                RuleMark(x: .value("Selected", label))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        selectionCallout(for: day)
                    }
            }
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
        .chartXSelection(value: $selectedLabel)
        .frame(height: isDense ? 120 : 140)
    }

    private var segments: [NappySegment] {
        data.flatMap { day in
            [
                NappySegment(id: "\(day.label)-wet",   label: day.label, type: "Wet",   count: day.wetCount),
                NappySegment(id: "\(day.label)-dirty", label: day.label, type: "Dirty", count: day.dirtyCount),
                NappySegment(id: "\(day.label)-mixed", label: day.label, type: "Mixed", count: day.mixedCount),
            ]
        }
    }

    private func selectionCallout(for day: DailyNappyData) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if day.wetCount > 0   { Text("Wet: \(day.wetCount)").foregroundStyle(Color.blue.opacity(0.8)) }
            if day.dirtyCount > 0 { Text("Dirty: \(day.dirtyCount)").foregroundStyle(Color.brown.opacity(0.9)) }
            if day.mixedCount > 0 { Text("Mixed: \(day.mixedCount)").foregroundStyle(Color.yellow.opacity(0.9)) }
            if day.totalCount == 0 { Text("No changes").foregroundStyle(.secondary) }
        }
        .font(.caption2.weight(.medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct NappySegment: Identifiable {
    let id: String
    let label: String
    let type: String
    let count: Int
}
