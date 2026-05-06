import BabyTrackerDomain
import BabyTrackerFeature
import Foundation

@MainActor
final class UserDefaultsFeedLiveActivitySnapshotCache: FeedLiveActivitySnapshotCaching {
    private enum Key {
        static let snapshot = "liveActivity.lastSnapshot"
    }

    private static let category = "LiveActivity"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> FeedLiveActivitySnapshot? {
        guard let data = userDefaults.data(forKey: Key.snapshot) else {
            AppLogger.shared.log(.debug, category: Self.category, "[cache] load — nothing stored")
            return nil
        }
        do {
            let snapshot = try JSONDecoder().decode(FeedLiveActivitySnapshot.self, from: data)
            AppLogger.shared.log(.debug, category: Self.category, "[cache] load — \(summarize(snapshot))")
            return snapshot
        } catch {
            AppLogger.shared.log(.error, category: Self.category, "[cache] load — decode failed: \(error.localizedDescription)")
            return nil
        }
    }

    func save(_ snapshot: FeedLiveActivitySnapshot?) {
        guard let snapshot else {
            userDefaults.removeObject(forKey: Key.snapshot)
            AppLogger.shared.log(.debug, category: Self.category, "[cache] save — cleared")
            return
        }
        do {
            let data = try JSONEncoder().encode(snapshot)
            userDefaults.set(data, forKey: Key.snapshot)
            AppLogger.shared.log(.debug, category: Self.category, "[cache] save — \(summarize(snapshot))")
        } catch {
            AppLogger.shared.log(.error, category: Self.category, "[cache] save — encode failed: \(error.localizedDescription)")
        }
    }

    private func summarize(_ snapshot: FeedLiveActivitySnapshot) -> String {
        "child=\(snapshot.childID.uuidString.prefix(8)) feed=\(snapshot.lastFeedKind.rawValue)@\(Int(snapshot.lastFeedAt.timeIntervalSince1970))"
    }
}
