import ActivityKit
import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation

@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    private let snapshotCache: any FeedLiveActivitySnapshotCaching
    private var activeActivityID: String?
    private var synchronizationTask: Task<Void, Never>?
    private var stateObservationTask: Task<Void, Never>?

    init(snapshotCache: any FeedLiveActivitySnapshotCaching) {
        self.snapshotCache = snapshotCache
    }

    var hasRunningActivity: Bool {
        !Activity<FeedLiveActivityAttributes>.activities.isEmpty
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizationTask?.cancel()
        synchronizationTask = Task { @MainActor [weak self] in
            await self?.reconcile(snapshot)
        }
    }

    /// Persists the snapshot the activity is actually displaying. The cache is the
    /// dedup oracle for `UpdateFeedLiveActivityUseCase`, so it must only advance once
    /// the ActivityKit write has truly landed — otherwise an interrupted update (app
    /// suspended mid-write, task cancelled) leaves the cache ahead of the live
    /// activity and every later update gets wrongly deduped. A superseded
    /// (cancelled) task must not clobber a newer snapshot, hence the cancellation guard.
    private func commitToCache(_ snapshot: FeedLiveActivitySnapshot?) {
        guard !Task.isCancelled else { return }
        snapshotCache.save(snapshot)
    }

    private func reconcile(_ snapshot: FeedLiveActivitySnapshot?) async {
        let activities = Activity<FeedLiveActivityAttributes>.activities

        guard let snapshot else {
            if !activities.isEmpty {
                Self.log(.info, "reconcile: snapshot is nil — ending \(activities.count) activity(ies)")
            }
            stateObservationTask?.cancel()
            stateObservationTask = nil
            await Self.endAllActivities()
            activeActivityID = nil
            commitToCache(nil)
            return
        }

        if let matchingActivity = activities.first(where: { activity in
            activity.attributes.childID == snapshot.childID
        }) {
            activeActivityID = matchingActivity.id
            observeActivityState(matchingActivity)
        } else if !activities.isEmpty {
            stateObservationTask?.cancel()
            stateObservationTask = nil
            await Self.endAllActivities()
            activeActivityID = nil
        } else {
            activeActivityID = nil
        }

        if let activeActivityID {
            let didUpdate = await Self.updateActivity(
                withID: activeActivityID,
                content: content(for: snapshot)
            )

            guard !Task.isCancelled else { return }

            if didUpdate {
                commitToCache(snapshot)
                return
            }

            self.activeActivityID = nil
        }

        guard !Task.isCancelled else { return }

        let authorizationInfo = ActivityAuthorizationInfo()
        guard authorizationInfo.areActivitiesEnabled else {
            Self.log(
                .error,
                "Cannot start Live Activity — Live Activities are disabled in system settings (areActivitiesEnabled == false)"
            )
            activeActivityID = nil
            return
        }

        do {
            let activity = try Activity.request(
                attributes: FeedLiveActivityAttributes(childID: snapshot.childID),
                content: content(for: snapshot),
                pushType: nil
            )
            activeActivityID = activity.id
            observeActivityState(activity)
            commitToCache(snapshot)
            Self.log(.info, "Started Live Activity \(activity.id) for child \(snapshot.childID)")
        } catch {
            // ActivityKit only permits starting a Live Activity while the app is in the
            // foreground; surfacing the error here is what makes this path observable.
            Self.log(.error, "Activity.request failed: \(error)")
            activeActivityID = nil
        }
    }

    private static func log(_ level: LogLevel, _ message: String) {
        AppLogger.shared.log(level, category: "LiveActivity", message)
    }

    private func observeActivityState(_ activity: Activity<FeedLiveActivityAttributes>) {
        stateObservationTask?.cancel()
        stateObservationTask = Task { @MainActor [weak self] in
            for await state in activity.activityStateUpdates {
                if state == .ended || state == .dismissed {
                    self?.activeActivityID = nil
                    self?.stateObservationTask = nil
                    return
                }
            }
        }
    }

    private func content(
        for snapshot: FeedLiveActivitySnapshot
    ) -> ActivityContent<FeedLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: FeedLiveActivityAttributes.ContentState(
                childID: snapshot.childID,
                childName: snapshot.childName,
                lastFeedKind: snapshot.lastFeedKind,
                lastFeedAt: snapshot.lastFeedAt,
                lastSleepAt: snapshot.lastSleepAt,
                activeSleepStartedAt: snapshot.activeSleepStartedAt,
                lastNappyAt: snapshot.lastNappyAt
            ),
            staleDate: nil,
            relevanceScore: 50
        )
    }

    private nonisolated static func endAllActivities() async {
        for activity in Activity<FeedLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private nonisolated static func updateActivity(
        withID id: String,
        content: ActivityContent<FeedLiveActivityAttributes.ContentState>
    ) async -> Bool {
        guard let activity = Activity<FeedLiveActivityAttributes>.activities.first(where: { $0.id == id }) else {
            return false
        }

        await activity.update(content)
        return true
    }
}
