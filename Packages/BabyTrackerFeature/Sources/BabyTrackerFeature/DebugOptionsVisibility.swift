import Foundation

/// Persists whether developer/debug options are visible in settings.
public let debugOptionsUnlockedKey = "nest.debugOptionsUnlocked"

/// Returns true when the incoming URL is the debug-options deep link.
///
/// Supported formats:
/// - `babytracker://debug-options`
/// - `babytracker:///debug-options`
public func isDebugOptionsDeepLink(_ url: URL) -> Bool {
    guard url.scheme?.localizedCaseInsensitiveCompare("babytracker") == .orderedSame else {
        return false
    }

    if url.host?.localizedCaseInsensitiveCompare("debug-options") == .orderedSame {
        return true
    }

    let normalizedPath = url.path
        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        .lowercased()
    return normalizedPath == "debug-options"
}
