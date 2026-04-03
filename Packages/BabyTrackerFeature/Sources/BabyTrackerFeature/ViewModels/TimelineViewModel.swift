import BabyTrackerDomain
import Foundation
import Observation

/// Provides timeline screen state by observing `AppModel.profile`.
///
/// Currently bridges `profile.timeline.*` and `profile.canManageEvents`.
/// When `ChildProfileScreenState` is removed (Stage 10) these will be
/// computed directly from raw AppModel data using `BuildTimelineBlocksUseCase`.
@MainActor
@Observable
public final class TimelineViewModel {
    private let appModel: AppModel

    public init(appModel: AppModel) {
        self.appModel = appModel
    }

    // MARK: - Computed state (bridge to profile.timeline)

    public var selectedDay: Date {
        appModel.profile?.timeline.selectedDay ?? Date()
    }

    public var selectedDayTitle: String {
        appModel.profile?.timeline.selectedDayTitle ?? ""
    }

    public var weekTitle: String {
        appModel.profile?.timeline.weekTitle ?? ""
    }

    public var pages: [TimelineDayPageState] {
        appModel.profile?.timeline.pages ?? []
    }

    public var selectedPageIndex: Int {
        appModel.profile?.timeline.selectedPageIndex ?? 0
    }

    public var showsJumpToToday: Bool {
        appModel.profile?.timeline.showsJumpToToday ?? false
    }

    public var canMoveToNextDay: Bool {
        appModel.profile?.timeline.canMoveToNextDay ?? false
    }

    public var syncMessage: String? {
        appModel.profile?.timeline.syncMessage
    }

    public var displayMode: TimelineScreenState.DisplayMode {
        appModel.profile?.timeline.displayMode ?? .day
    }

    public var stripColumns: [TimelineStripDayColumnViewState] {
        appModel.profile?.timeline.stripColumns ?? []
    }

    public var canManageEvents: Bool {
        appModel.profile?.canManageEvents ?? false
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
}
