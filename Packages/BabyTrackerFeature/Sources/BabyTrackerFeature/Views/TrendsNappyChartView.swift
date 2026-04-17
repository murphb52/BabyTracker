import Charts
import SwiftUI

/// Stacked bar chart for nappy types (wet / dirty / mixed) per day.
///
/// Owns its own selection state so that touching a bar shows a breakdown callout
/// for that day. The chart generates its own legend.
struct TrendsNappyChartView: View {
    let data: [DailyNappyData]
    var averageValue: Int? = nil

    @State private var selectedKey: String?

    private var isDense: Bool { data.count > 14 }

    var body: some View {
        Chart {
            // Include all three types for every day (even when count is 0) so Swift Charts
            // establishes a consistent wet → dirty → mixed stacking order across all bars.
            ForEach(segments) { segment in
                BarMark(
                    x: .value("Day", segment.dayKey),
                    y: .value("Count", segment.count)
                )
                .foregroundStyle(by: .value("Type", segment.type))
                .opacity(selectedKey == nil || selectedKey == segment.dayKey ? 1 : 0.3)
            }

            if let avg = averageValue {
                RuleMark(y: .value("Average", avg))
                    .foregroundStyle(.orange.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    .annotation(position: .top, alignment: .trailing, spacing: 2) {
                        Text("Avg")
                            .font(.system(size: 9).weight(.medium))
                            .foregroundStyle(.orange.opacity(0.9))
                    }
            }

            if let selectedDay {
                RuleMark(x: .value("Selected", selectedDay.domainKey))
                    .foregroundStyle(.secondary.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .annotation(position: .top, spacing: 4) {
                        selectionCallout(for: selectedDay.day)
                    }
            }
        }
        .chartForegroundStyleScale([
            "Wet":   Color.blue.opacity(0.6),
            "Dirty": Color.brown.opacity(0.75),
            "Mixed": Color.yellow.opacity(0.85),
        ])
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisValueLabel(collisionResolution: .greedy(minimumSpacing: 4)) {
                    if let key = value.as(String.self), let point = dayPoints.first(where: { $0.domainKey == key }) {
                        Text(point.day.label)
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
        .chartYScale(domain: 0...yAxisUpperBound)
        .chartLegend(position: .bottom, alignment: .leading)
        .chartXSelection(value: $selectedKey)
        .frame(height: isDense ? 120 : 140)
    }

    private var segments: [NappySegment] {
        dayPoints.flatMap { point in
            [
                NappySegment(id: "\(point.id)-wet", dayKey: point.domainKey, type: "Wet", count: point.day.wetCount),
                NappySegment(id: "\(point.id)-dirty", dayKey: point.domainKey, type: "Dirty", count: point.day.dirtyCount),
                NappySegment(id: "\(point.id)-mixed", dayKey: point.domainKey, type: "Mixed", count: point.day.mixedCount),
            ]
        }
    }

    private var dayPoints: [NappyDayPoint] {
        data.enumerated().map { index, day in
            NappyDayPoint(id: index, day: day)
        }
    }

    private var selectedDay: NappyDayPoint? {
        guard let selectedKey else { return nil }
        return dayPoints.first(where: { $0.domainKey == selectedKey })
    }

    private var xAxisValues: [String] {
        TrendsChartLayout.axisValues(count: dayPoints.count, desiredVisibleCount: isDense ? 5 : dayPoints.count)
            .map { dayPoints[$0].domainKey }
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
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private var yAxisUpperBound: Int {
        var values = data.map(\.totalCount)
        if let avg = averageValue { values.append(avg) }
        return TrendsChartLayout.yDomainUpperBound(for: values)
    }
}

private struct NappyDayPoint: Identifiable {
    let id: Int
    let day: DailyNappyData

    var domainKey: String {
        "day-\(id)"
    }
}

private struct NappySegment: Identifiable {
    let id: String
    let dayKey: String
    let type: String
    let count: Int
}

#Preview("Standard") {
    let today = Date()
    TrendsNappyChartView(
        data: [
            DailyNappyData(date: today, label: "Mon", wetCount: 3, dirtyCount: 1, mixedCount: 1, dryCount: 0),
            DailyNappyData(date: today, label: "Tue", wetCount: 2, dirtyCount: 2, mixedCount: 0, dryCount: 1),
            DailyNappyData(date: today, label: "Wed", wetCount: 4, dirtyCount: 1, mixedCount: 2, dryCount: 0),
        ]
    )
    .padding()
}

#Preview("Zero state") {
    let today = Date()
    TrendsNappyChartView(
        data: [
            DailyNappyData(date: today, label: "Mon", wetCount: 0, dirtyCount: 0, mixedCount: 0, dryCount: 0),
            DailyNappyData(date: today, label: "Tue", wetCount: 0, dirtyCount: 0, mixedCount: 0, dryCount: 0),
        ]
    )
    .padding()
}
