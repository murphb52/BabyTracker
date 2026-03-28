@MainActor
public protocol HapticFeedbackProviding {
    func play(_ event: HapticEvent)
}
