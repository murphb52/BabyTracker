import Foundation

public enum FeedLiveActivityDeepLink {
    public static let scheme = "babytracker"
    private static let sleepHost = "sleep"
    private static let endPath = "/end"
    private static let childIDItemName = "childID"

    public static func endSleepURL(childID: UUID) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = sleepHost
        components.path = endPath
        components.queryItems = [
            URLQueryItem(name: childIDItemName, value: childID.uuidString),
        ]
        return components.url
    }

    public static func endSleepChildID(from url: URL) -> UUID? {
        guard matchesEndSleep(url) else {
            return nil
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let childIDValue = components.queryItems?.first(where: { $0.name == childIDItemName })?.value else {
            return nil
        }

        return UUID(uuidString: childIDValue)
    }

    public static func matchesEndSleep(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        return components.scheme == scheme &&
            components.host == sleepHost &&
            components.path == endPath
    }
}
