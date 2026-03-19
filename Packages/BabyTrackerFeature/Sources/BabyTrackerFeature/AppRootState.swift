public struct AppRootState: Equatable, Sendable {
    public var title: String
    public var message: String
    public var stageMessage: String

    public init(title: String, message: String, stageMessage: String) {
        self.title = title
        self.message = message
        self.stageMessage = stageMessage
    }

    public static let foundation = AppRootState(
        title: "No child profile yet",
        message: "Stage 0 replaces the starter template with the foundation the MVP needs.",
        stageMessage: "Stage 1 will add child profile setup, identity, and caregiver sharing."
    )
}
