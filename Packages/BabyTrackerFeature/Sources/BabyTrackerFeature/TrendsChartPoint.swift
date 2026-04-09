import Foundation

struct TrendsChartPoint: Identifiable, Equatable, Sendable {
    let id: Int
    let label: String
    let value: Int

    var domainKey: String {
        "point-\(id)"
    }

    static func makePoints(from entries: [(String, Int)]) -> [TrendsChartPoint] {
        entries.enumerated().map { index, entry in
            TrendsChartPoint(id: index, label: entry.0, value: entry.1)
        }
    }
}

enum TrendsChartLayout {
    static func axisValues(count: Int, desiredVisibleCount: Int) -> [Int] {
        guard count > 0 else { return [] }
        guard desiredVisibleCount > 0 else { return [0] }

        if count <= desiredVisibleCount {
            return Array(0..<count)
        }

        let step = Double(count - 1) / Double(max(1, desiredVisibleCount - 1))
        var values: [Int] = []

        for position in 0..<desiredVisibleCount {
            let value = Int((Double(position) * step).rounded())
            if values.last != value {
                values.append(value)
            }
        }

        if values.last != count - 1 {
            values.append(count - 1)
        }

        return values
    }

    static func yDomainUpperBound(for values: [Int]) -> Int {
        let maxValue = max(1, values.max() ?? 1)
        let padding = max(1, Int(ceil(Double(maxValue) * 0.2)))
        return maxValue + padding
    }
}
