import Foundation

public struct TimelineScreenState: Equatable, Sendable {
    public let selectedDay: Date
    public let selectedDayTitle: String
    public let weekTitle: String
    public let pages: [TimelineDayPageState]
    public let selectedPageIndex: Int
    public let showsJumpToToday: Bool
    public let canMoveToNextDay: Bool
    public let syncMessage: String?

    public init(
        selectedDay: Date,
        selectedDayTitle: String,
        weekTitle: String,
        pages: [TimelineDayPageState],
        selectedPageIndex: Int,
        showsJumpToToday: Bool,
        canMoveToNextDay: Bool,
        syncMessage: String?
    ) {
        self.selectedDay = selectedDay
        self.selectedDayTitle = selectedDayTitle
        self.weekTitle = weekTitle
        self.pages = pages
        self.selectedPageIndex = selectedPageIndex
        self.showsJumpToToday = showsJumpToToday
        self.canMoveToNextDay = canMoveToNextDay
        self.syncMessage = syncMessage
    }
}
