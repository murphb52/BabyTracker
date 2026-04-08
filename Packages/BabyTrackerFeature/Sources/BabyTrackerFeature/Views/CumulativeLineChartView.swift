import SwiftUI

/// A two-line overlay chart for the Today tab.
///
/// Draws a solid colored line for today's cumulative total by hour and a dotted
/// secondary line for the 7-day average cumulative total. The x-axis spans all
/// 24 hours; the y-axis auto-scales to the maximum of both series.
struct CumulativeLineChartView: View {
    let series: HourlyCumulativeSeries
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }

                let maxValue = max(
                    1,
                    series.todayCumulative.max() ?? 0,
                    series.averageCumulative.max() ?? 0
                )

                func point(hour: Int, value: Int, in size: CGSize) -> CGPoint {
                    let x = (CGFloat(hour) / 23.0) * size.width
                    let y = size.height - (CGFloat(value) / CGFloat(maxValue)) * size.height
                    return CGPoint(x: x, y: y)
                }

                // Average line (dotted)
                var avgPath = Path()
                for h in 0..<24 {
                    let pt = point(hour: h, value: series.averageCumulative[h], in: size)
                    if h == 0 { avgPath.move(to: pt) } else { avgPath.addLine(to: pt) }
                }
                context.stroke(
                    avgPath,
                    with: .color(.secondary.opacity(0.6)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                )

                // Today line (solid)
                var todayPath = Path()
                for h in 0..<24 {
                    let pt = point(hour: h, value: series.todayCumulative[h], in: size)
                    if h == 0 { todayPath.move(to: pt) } else { todayPath.addLine(to: pt) }
                }
                context.stroke(
                    todayPath,
                    with: .color(tint),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 70)

            xAxisLabels
        }
    }

    private var xAxisLabels: some View {
        // Show labels at midnight (0), 6am (6), noon (12), 6pm (18)
        HStack {
            Text("12a")
            Spacer()
            Text("6a")
            Spacer()
            Text("12p")
            Spacer()
            Text("6p")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
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
