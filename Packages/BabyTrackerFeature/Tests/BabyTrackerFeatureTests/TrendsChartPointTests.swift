@testable import BabyTrackerFeature
import Testing

struct TrendsChartPointTests {
    @Test
    func makePointsAssignsUniqueIDsWhenLabelsRepeat() {
        let points = TrendsChartPoint.makePoints(from: [
            ("F", 660),
            ("S", 800),
            ("M", 700),
            ("T", 480),
            ("W", 780),
            ("T", 825),
        ])

        #expect(points.map(\.id) == [0, 1, 2, 3, 4, 5])
        #expect(points.map(\.label) == ["F", "S", "M", "T", "W", "T"])
        #expect(points.map(\.value) == [660, 800, 700, 480, 780, 825])
    }

    @Test
    func axisValuesIncludeFirstAndLastPointWhenDense() {
        let values = TrendsChartLayout.axisValues(count: 30, desiredVisibleCount: 5)

        #expect(values.first == 0)
        #expect(values.last == 29)
        #expect(values.count >= 5)
    }

    @Test
    func yDomainUpperBoundAddsHeadroomAboveLargestValue() {
        let upperBound = TrendsChartLayout.yDomainUpperBound(for: [660, 800, 700, 480, 780, 825])

        #expect(upperBound > 825)
    }
}
