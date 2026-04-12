import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsFeedLiveActivitySnapshotCache: FeedLiveActivitySnapshotCaching {
    private enum Key {
        static let snapshot = "liveActivity.lastSnapshot"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> FeedLiveActivitySnapshot? {
        guard let data = userDefaults.data(forKey: Key.snapshot) else { return nil }
        return try? JSONDecoder().decode(FeedLiveActivitySnapshot.self, from: data)
    }

    func save(_ snapshot: FeedLiveActivitySnapshot?) {
        if let snapshot {
            userDefaults.set(try? JSONEncoder().encode(snapshot), forKey: Key.snapshot)
        } else {
            userDefaults.removeObject(forKey: Key.snapshot)
        }
    }
}
