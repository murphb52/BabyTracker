import Foundation

public struct TimelineScreenState: Equatable, Sendable {
    public enum DisplayMode: Equatable, Sendable {
        case day
        case weekStrip
    }

    public let selectedDay: Date
    public let selectedDayTitle: String
    public let weekTitle: String
    public let pages: [TimelineDayPageState]
    public let selectedPageIndex: Int
    public let showsJumpToToday: Bool
    public let canMoveToNextDay: Bool
    public let syncMessage: String?
    public let displayMode: DisplayMode
    public let stripColumns: [TimelineStripDayColumnViewState]
    public let selectedStripColumnIndex: Int

    public init(
        selectedDay: Date,
        selectedDayTitle: String,
        weekTitle: String,
        pages: [TimelineDayPageState],
        selectedPageIndex: Int,
        showsJumpToToday: Bool,
        canMoveToNextDay: Bool,
        syncMessage: String?,
        displayMode: DisplayMode,
        stripColumns: [TimelineStripDayColumnViewState],
        selectedStripColumnIndex: Int
    ) {
        self.selectedDay = selectedDay
        self.selectedDayTitle = selectedDayTitle
        self.weekTitle = weekTitle
        self.pages = pages
        self.selectedPageIndex = selectedPageIndex
        self.showsJumpToToday = showsJumpToToday
        self.canMoveToNextDay = canMoveToNextDay
        self.syncMessage = syncMessage
        self.displayMode = displayMode
        self.stripColumns = stripColumns
        self.selectedStripColumnIndex = selectedStripColumnIndex
    }
}
