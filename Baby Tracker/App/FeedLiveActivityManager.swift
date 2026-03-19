import ActivityKit
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation

@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    private var activeActivityID: String?
    private var lastSnapshot: FeedLiveActivitySnapshot?
    private var synchronizationTask: Task<Void, Never>?

    func synchronize(with snapshot: FeedLiveActivitySnapshot?) {
        synchronizationTask?.cancel()
        synchronizationTask = Task { @MainActor [weak self] in
            await self?.reconcile(snapshot)
        }
    }

    private func reconcile(_ snapshot: FeedLiveActivitySnapshot?) async {
        let activities = Activity<FeedLiveActivityAttributes>.activities

        guard let snapshot else {
            await Self.endAllActivities()
            activeActivityID = nil
            lastSnapshot = nil
            return
        }

        if let matchingActivity = activities.first(where: { activity in
            activity.attributes.childID == snapshot.childID
        }) {
            activeActivityID = matchingActivity.id
        } else if !activities.isEmpty {
            await Self.endAllActivities()
            activeActivityID = nil
        } else {
            activeActivityID = nil
        }

        guard lastSnapshot != snapshot || activeActivityID == nil else {
            return
        }

        if let activeActivityID {
            let didUpdate = await Self.updateActivity(
                withID: activeActivityID,
                content: content(for: snapshot)
            )

            if didUpdate {
                lastSnapshot = snapshot
                return
            }

            self.activeActivityID = nil
        }

        do {
            let activity = try Activity.request(
                attributes: FeedLiveActivityAttributes(childID: snapshot.childID),
                content: content(for: snapshot),
                pushType: nil
            )
            activeActivityID = activity.id
            lastSnapshot = snapshot
        } catch {
            activeActivityID = nil
            lastSnapshot = nil
        }
    }

    private func content(
        for snapshot: FeedLiveActivitySnapshot
    ) -> ActivityContent<FeedLiveActivityAttributes.ContentState> {
        ActivityContent(
            state: FeedLiveActivityAttributes.ContentState(
                childName: snapshot.childName,
                lastFeedKind: snapshot.lastFeedKind,
                lastFeedAt: snapshot.lastFeedAt
            ),
            staleDate: nil
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
