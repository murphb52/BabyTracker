public protocol AppReviewPromptStateStoring: AnyObject {
    var loggedEventCount: Int { get set }
    var hasRequestedReview: Bool { get set }
}

public protocol AppReviewRequesting: AnyObject {
    func requestReview()
}

public final class NoOpAppReviewPromptStateStore: AppReviewPromptStateStoring {
    public var loggedEventCount: Int
    public var hasRequestedReview: Bool

    public init(
        loggedEventCount: Int = 0,
        hasRequestedReview: Bool = false
    ) {
        self.loggedEventCount = loggedEventCount
        self.hasRequestedReview = hasRequestedReview
    }
}

public final class NoOpAppReviewRequester: AppReviewRequesting {
    public init() {}

    public func requestReview() {}
}
