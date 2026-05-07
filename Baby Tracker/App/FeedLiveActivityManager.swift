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
/// All ActivityKit entry points (`request`, `update`, `end`) are funneled
/// through `nonisolated static` helpers that take only `Sendable` values
/// (ids, attributes, content). The instance itself stays `@MainActor` for
/// state and logging; this layout avoids "sending non-Sendable Activity
/// across actor boundaries" warnings under Swift 6 strict concurrency.
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
            runningActivityIDs: activities.map { "\($0.id)(\(String(describing: $0.activityState)))" },
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
            if !activities.isEmpty {
                log(.info, "[end] ending \(activities.count) activities — reason=snapshot=nil")
                await Self.endAll()
            }
            activeActivityID = nil
            stateObservationTask?.cancel()
            stateObservationTask = nil
            lastSyncSummary = "ended (snapshot nil)"
            return
        }

        // Drop stale activities for OTHER children (we only track one at a time).
        let mismatchedIDs = activities
            .filter { $0.attributes.childID != snapshot.childID }
            .map(\.id)
        if !mismatchedIDs.isEmpty {
            log(.info, "[end] ending \(mismatchedIDs.count) stale activities for other children")
            await Self.end(ids: mismatchedIDs)
        }

        // Match: an activity already exists for this child — try to update it.
        if let matching = activities.first(where: { $0.attributes.childID == snapshot.childID }) {
            let matchingID = matching.id
            activeActivityID = matchingID
            observeActivityState(matching)

            log(.info, "[update] id=\(matchingID)")
            let didUpdate = await Self.update(id: matchingID, content: content(for: snapshot))
            guard !Task.isCancelled else { return }
            if didUpdate {
                log(.info, "[update] succeeded id=\(matchingID)")
                lastSyncSummary = "updated \(Self.summarize(snapshot))"
                return
            }

            // Update failed — fall through and request a fresh activity.
            log(.warning, "[update] activity disappeared from system before update id=\(matchingID), falling back to request")
            activeActivityID = nil
        }

        guard !Task.isCancelled else { return }

        requestNewActivity(snapshot: snapshot)
    }

    // MARK: - Request

    private func requestNewActivity(snapshot: FeedLiveActivitySnapshot) {
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

    // MARK: - State observation

    private func observeActivityState(_ activity: Activity<FeedLiveActivityAttributes>) {
        stateObservationTask?.cancel()
        let id = activity.id
        stateObservationTask = Task { @MainActor [weak self] in
            for await state in activity.activityStateUpdates {
                self?.log(.info, "[observe] id=\(id) → \(String(describing: state))")
                if state == .ended || state == .dismissed || state == .stale {
                    self?.activeActivityID = nil
                    self?.stateObservationTask = nil
                    return
                }
            }
        }
    }

    // MARK: - ActivityKit nonisolated wrappers

    /// All ActivityKit `await` calls live here so the non-Sendable
    /// `Activity<...>` reference never crosses an actor boundary.
    private nonisolated static func update(
        id: String,
        content: ActivityContent<FeedLiveActivityAttributes.ContentState>
    ) async -> Bool {
        guard let activity = Activity<FeedLiveActivityAttributes>.activities.first(where: { $0.id == id }) else {
            return false
        }
        await activity.update(content)
        return true
    }

    private nonisolated static func end(ids: [String]) async {
        let idSet = Set(ids)
        for activity in Activity<FeedLiveActivityAttributes>.activities where idSet.contains(activity.id) {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private nonisolated static func endAll() async {
        for activity in Activity<FeedLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
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
