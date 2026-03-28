@MainActor
public struct NoOpHapticFeedbackProvider: HapticFeedbackProviding {
    public init() {}

    public func play(_ event: HapticEvent) {}
}
