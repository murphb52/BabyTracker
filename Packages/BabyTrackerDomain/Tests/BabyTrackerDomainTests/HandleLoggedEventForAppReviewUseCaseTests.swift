import XCTest
@testable import BabyTrackerDomain

final class HandleLoggedEventForAppReviewUseCaseTests: XCTestCase {
    func testExecuteReturnsFalseBeforeThreshold() {
        let stateStore = InMemoryAppReviewPromptStateStore()
        let useCase = HandleLoggedEventForAppReviewUseCase(stateStore: stateStore)

        let shouldRequest = useCase.execute(.init(minimumLoggedEventsBeforePrompt: 3))

        XCTAssertFalse(shouldRequest)
        XCTAssertEqual(stateStore.loggedEventCount, 1)
        XCTAssertFalse(stateStore.hasRequestedReview)
    }

    func testExecuteReturnsTrueAtThresholdAndMarksPromptRequested() {
        let stateStore = InMemoryAppReviewPromptStateStore(loggedEventCount: 2)
        let useCase = HandleLoggedEventForAppReviewUseCase(stateStore: stateStore)

        let shouldRequest = useCase.execute(.init(minimumLoggedEventsBeforePrompt: 3))

        XCTAssertTrue(shouldRequest)
        XCTAssertEqual(stateStore.loggedEventCount, 3)
        XCTAssertTrue(stateStore.hasRequestedReview)
    }

    func testExecuteReturnsFalseAfterPromptWasAlreadyRequested() {
        let stateStore = InMemoryAppReviewPromptStateStore(
            loggedEventCount: 30,
            hasRequestedReview: true
        )
        let useCase = HandleLoggedEventForAppReviewUseCase(stateStore: stateStore)

        let shouldRequest = useCase.execute(.init(minimumLoggedEventsBeforePrompt: 20))

        XCTAssertFalse(shouldRequest)
        XCTAssertEqual(stateStore.loggedEventCount, 31)
        XCTAssertTrue(stateStore.hasRequestedReview)
    }
}

private final class InMemoryAppReviewPromptStateStore: AppReviewPromptStateStoring {
    var loggedEventCount: Int
    var hasRequestedReview: Bool

    init(
        loggedEventCount: Int = 0,
        hasRequestedReview: Bool = false
    ) {
        self.loggedEventCount = loggedEventCount
        self.hasRequestedReview = hasRequestedReview
    }
}
