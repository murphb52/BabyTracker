import ActivityKit
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation

@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    private var activeActivityID: String?
    private var synchronizationTask: Task<Void, Never>?
    private var stateObservationTask: Task<Void, Never>?

    var hasRunningActivity: Bool {
        !Activity<FeedLiveActivityAttributes>.activities.isEmpty
    }

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizationTask?.cancel()
        synchronizationTask = Task { @MainActor [weak self] in
            await self?.reconcile(snapshot)
        }
    }

    private func reconcile(_ snapshot: FeedLiveActivitySnapshot?) async {
        let activities = Activity<FeedLiveActivityAttributes>.activities

        guard let snapshot else {
            stateObservationTask?.cancel()
            stateObservationTask = nil
            await Self.endAllActivities()
            activeActivityID = nil
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
                return
            }

            self.activeActivityID = nil
        }

        guard !Task.isCancelled else { return }

        do {
            let activity = try Activity.request(
                attributes: FeedLiveActivityAttributes(childID: snapshot.childID),
                content: content(for: snapshot),
                pushType: nil
            )
            activeActivityID = activity.id
            observeActivityState(activity)
        } catch {
            activeActivityID = nil
        }
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
