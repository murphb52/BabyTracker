public struct HandleLoggedEventForAppReviewUseCase: UseCase {
    public struct Input {
        public let minimumLoggedEventsBeforePrompt: Int

        public init(minimumLoggedEventsBeforePrompt: Int = 20) {
            self.minimumLoggedEventsBeforePrompt = minimumLoggedEventsBeforePrompt
        }
    }

    private let stateStore: any AppReviewPromptStateStoring

    public init(stateStore: any AppReviewPromptStateStoring) {
        self.stateStore = stateStore
    }

    public func execute(_ input: Input) -> Bool {
        let nextCount = stateStore.loggedEventCount + 1
        stateStore.loggedEventCount = nextCount

        guard stateStore.hasRequestedReview == false else {
            return false
        }

        let minimumCount = max(1, input.minimumLoggedEventsBeforePrompt)
        guard nextCount >= minimumCount else {
            return false
        }

        stateStore.hasRequestedReview = true
        return true
    }
}
