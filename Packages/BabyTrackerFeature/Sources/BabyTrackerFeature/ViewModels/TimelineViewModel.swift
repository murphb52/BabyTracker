import BabyTrackerDomain
import Foundation
import Observation

/// Provides timeline screen state computed directly from `AppModel` flat data.
@MainActor
@Observable
public final class TimelineViewModel {
    private let appModel: AppModel
    private let calendar = Calendar.autoupdatingCurrent

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state

    public var selectedDay: Date {
        appModel.timelineSelectedDay
    }

    public var selectedDayTitle: String {
        timelineDayTitle(for: appModel.timelineSelectedDay)
    }

    public var weekTitle: String {
        let dates = appModel.timelinePages.map(\.date)
        guard let start = dates.first, let end = dates.last else { return "" }
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            return "\(start.formatted(.dateTime.month(.abbreviated))) \(start.formatted(.dateTime.day()))-\(end.formatted(.dateTime.day()))"
        }
        return "\(start.formatted(.dateTime.month(.abbreviated).day()))-\(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    public var pages: [TimelineDayGridPageState] {
        appModel.timelinePages
    }

    public var selectedPageIndex: Int {
        appModel.timelinePages.firstIndex(where: { page in
            calendar.isDate(page.date, inSameDayAs: appModel.timelineSelectedDay)
        }) ?? 0
    }

    public var showsJumpToToday: Bool {
        appModel.timelineSelectedDay != calendar.startOfDay(for: .now)
    }

    public var canMoveToNextDay: Bool { true }

    public var syncMessage: String? {
        let status = appModel.cloudKitStatus
        guard !status.isAccountUnavailable else { return nil }
        switch status.state {
        case .upToDate: return nil
        case .pendingSync: return "Changes are saved locally and will sync automatically."
        case .syncing, .failed: return status.detailMessage
        }
    }

    public var displayMode: TimelineDisplayMode {
        appModel.timelineDisplayMode
    }

    public var stripColumns: [TimelineStripDayColumnViewState] {
        appModel.timelineStripColumns
    }

    public var canManageEvents: Bool {
        guard let membership = appModel.currentMembership else { return false }
        return ChildAccessPolicy.canPerform(.editEvent, membership: membership)
            && ChildAccessPolicy.canPerform(.deleteEvent, membership: membership)
    }

    // MARK: - Navigation actions

    public func showPreviousDay() {
        appModel.showPreviousTimelineDay()
    }

    public func showNextDay() {
        appModel.showNextTimelineDay()
    }

    public func jumpToToday() {
        appModel.jumpTimelineToToday()
    }

    public func showDay(_ day: Date) {
        appModel.showTimelineDay(day)
    }

    public func toggleDisplayMode() {
        appModel.toggleTimelineDisplayMode()
    }

    // MARK: - Private helpers

    private func timelineDayTitle(for day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .numeric, time: .omitted)
    }
}
