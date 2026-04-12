import ActivityKit
import BabyTrackerFeature
import BabyTrackerLiveActivities
import Foundation

@MainActor
final class FeedLiveActivityManager: FeedLiveActivityManaging {
    private var activeActivityID: String?
    private var synchronizationTask: Task<Void, Never>?
    private let userDefaults: UserDefaults

    private enum CacheKey {
        static let lastSnapshot = "liveActivity.lastSnapshot"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    private func loadCachedSnapshot() -> FeedLiveActivitySnapshot? {
        guard let data = userDefaults.data(forKey: CacheKey.lastSnapshot) else { return nil }
        return try? JSONDecoder().decode(FeedLiveActivitySnapshot.self, from: data)
    }

    private func cacheSnapshot(_ snapshot: FeedLiveActivitySnapshot) {
        userDefaults.set(try? JSONEncoder().encode(snapshot), forKey: CacheKey.lastSnapshot)
    }

    private func clearCache() {
        userDefaults.removeObject(forKey: CacheKey.lastSnapshot)
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
            await Self.endAllActivities()
            clearCache()
            activeActivityID = nil
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

        if let activeActivityID {
            if snapshot == loadCachedSnapshot() {
                return
            }

            let didUpdate = await Self.updateActivity(
                withID: activeActivityID,
                content: content(for: snapshot)
            )

            guard !Task.isCancelled else { return }

            if didUpdate {
                cacheSnapshot(snapshot)
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
            cacheSnapshot(snapshot)
        } catch {
            activeActivityID = nil
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
