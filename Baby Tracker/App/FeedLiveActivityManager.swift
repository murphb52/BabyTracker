import ActivityKit
import BabyTrackerDomain
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation

/// Manages the lock-screen Live Activity for the currently selected child.
///
/// Designed as an explicit serialised state machine. Every reconcile begins by
/// reading the live truth from `Activity<…>.activities` — the in-memory
/// `activeActivityID` is treated as a hint, never authoritative — so a system
/// dismissal between reconciles cannot leave us out of sync.
///
/// Every public entry point and every ActivityKit call is logged through
/// `AppLogger.shared` under category `LiveActivity` so the in-app log viewer
/// can be used to follow each step end-to-end.
///
/// Update-budget discipline lives one level up in `UpdateFeedLiveActivityUseCase`,
/// which only forwards a `synchronize` call when the snapshot has actually
/// changed (or the activity has died and needs restarting). The manager itself
/// trusts that signal and does not impose its own time-based throttle —
/// throttling here would risk dropping a legitimate update from a fresh event.
@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    private static let category = "LiveActivity"

    private var activeActivityID: String?
    private var lastSyncSummary: String?
    private var synchronizationTask: Task<Void, Never>?
    private var stateObservationTask: Task<Void, Never>?

    var hasRunningActivity: Bool {
        !Activity<FeedLiveActivityAttributes>.activities.isEmpty
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        let summary = Self.summarize(snapshot)
        log(.debug, "[synchronize] requested snapshot=\(summary)")
        if synchronizationTask != nil {
            log(.debug, "[synchronize] cancelling in-flight reconcile to coalesce")
            synchronizationTask?.cancel()
        }
        synchronizationTask = Task { @MainActor [weak self] in
            await self?.reconcile(snapshot)
        }
    }

    func currentDiagnostic() -> FeedLiveActivityDiagnostic {
        let activities = Activity<FeedLiveActivityAttributes>.activities
        return FeedLiveActivityDiagnostic(
            hasRunningActivity: !activities.isEmpty,
            activeActivityID: activeActivityID,
            runningActivityIDs: activities.map { "\($0.id)(\($0.activityState))" },
            systemAuthorizationGranted: ActivityAuthorizationInfo().areActivitiesEnabled,
            lastSyncSummary: lastSyncSummary
        )
    }

    // MARK: - Reconcile

    private func reconcile(_ snapshot: FeedLiveActivitySnapshot?) async {
        defer { synchronizationTask = nil }

        let activities = Activity<FeedLiveActivityAttributes>.activities
        log(.debug, "[reconcile] start running=\(activities.count) activeID=\(activeActivityID ?? "nil")")

        guard let snapshot else {
            await endAll(activities, reason: "snapshot=nil")
            activeActivityID = nil
            stateObservationTask?.cancel()
            stateObservationTask = nil
            lastSyncSummary = "ended (snapshot nil)"
            return
        }

        // Drop stale activities for OTHER children (we only track one at a time).
        let mismatched = activities.filter { $0.attributes.childID != snapshot.childID }
        if !mismatched.isEmpty {
            log(.info, "[reconcile] ending \(mismatched.count) stale activities for other children")
            await endAll(mismatched, reason: "stale child")
        }

        // Match: an activity already exists for this child — try to update it.
        if let matching = activities.first(where: { $0.attributes.childID == snapshot.childID }) {
            activeActivityID = matching.id
            observeActivityState(matching)

            let didUpdate = await update(activity: matching, snapshot: snapshot)
            guard !Task.isCancelled else { return }
            if didUpdate {
                lastSyncSummary = "updated \(Self.summarize(snapshot))"
                return
            }

            // Update failed — fall through and request a fresh activity.
            log(.warning, "[reconcile] update failed for id=\(matching.id), falling back to request")
            activeActivityID = nil
        }

        guard !Task.isCancelled else { return }

        await request(snapshot: snapshot)
    }

    // MARK: - ActivityKit calls

    private func request(snapshot: FeedLiveActivitySnapshot) async {
        let auth = ActivityAuthorizationInfo()
        guard auth.areActivitiesEnabled else {
            log(.warning, "[request] aborted: system authorization denied — Live Activities disabled in iOS Settings")
            lastSyncSummary = "blocked (system auth denied)"
            return
        }
        log(.info, "[request] auth=granted frequentPushes=\(auth.frequentPushesEnabled)")

        do {
            let activity = try Activity.request(
                attributes: FeedLiveActivityAttributes(childID: snapshot.childID),
                content: content(for: snapshot),
                pushType: nil
            )
            activeActivityID = activity.id
            lastSyncSummary = "started \(Self.summarize(snapshot))"
            log(.info, "[request] started id=\(activity.id) child=\(snapshot.childID)")
            observeActivityState(activity)
        } catch {
            activeActivityID = nil
            lastSyncSummary = "request failed: \(error.localizedDescription)"
            log(.error, "[request] Activity.request failed: \(error.localizedDescription)")
        }
    }

    private func update(
        activity: Activity<FeedLiveActivityAttributes>,
        snapshot: FeedLiveActivitySnapshot
    ) async -> Bool {
        log(.info, "[update] id=\(activity.id) state=\(activity.activityState)")
        // Re-fetch the current activity to avoid acting on a reference that
        // was already ended by the system between our enumeration and now.
        guard Activity<FeedLiveActivityAttributes>.activities.contains(where: { $0.id == activity.id }) else {
            log(.warning, "[update] activity disappeared from system before update id=\(activity.id)")
            return false
        }
        await activity.update(content(for: snapshot))
        log(.info, "[update] succeeded id=\(activity.id)")
        return true
    }

    private func endAll(
        _ activities: [Activity<FeedLiveActivityAttributes>],
        reason: String
    ) async {
        guard !activities.isEmpty else { return }
        log(.info, "[end] ending \(activities.count) activities — reason=\(reason)")
        for activity in activities {
            log(.debug, "[end] id=\(activity.id) state=\(activity.activityState)")
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func observeActivityState(_ activity: Activity<FeedLiveActivityAttributes>) {
        stateObservationTask?.cancel()
        let id = activity.id
        stateObservationTask = Task { @MainActor [weak self] in
            for await state in activity.activityStateUpdates {
                self?.log(.info, "[observe] id=\(id) → \(state)")
                if state == .ended || state == .dismissed || state == .stale {
                    self?.activeActivityID = nil
                    self?.stateObservationTask = nil
                    return
                }
            }
        }
    }

    // MARK: - Helpers

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

    private func log(_ level: LogLevel, _ message: String) {
        AppLogger.shared.log(level, category: Self.category, message)
    }

    static func summarize(_ snapshot: FeedLiveActivitySnapshot?) -> String {
        guard let snapshot else { return "nil" }
        var parts: [String] = [
            "child=\(snapshot.childID.uuidString.prefix(8))",
            "feed=\(snapshot.lastFeedKind.rawValue)@\(Int(snapshot.lastFeedAt.timeIntervalSince1970))"
        ]
        if let activeSleep = snapshot.activeSleepStartedAt {
            parts.append("activeSleep@\(Int(activeSleep.timeIntervalSince1970))")
        } else if let lastSleep = snapshot.lastSleepAt {
            parts.append("sleep@\(Int(lastSleep.timeIntervalSince1970))")
        }
        if let nappy = snapshot.lastNappyAt {
            parts.append("nappy@\(Int(nappy.timeIntervalSince1970))")
        }
        return parts.joined(separator: " ")
    }
}
