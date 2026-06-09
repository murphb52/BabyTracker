@testable import BabyTrackerFeature
import BabyTrackerDomain
import Foundation
import Testing

@MainActor
struct ResetFeedLiveActivityUseCaseTests {
    // MARK: - Activity running

    @Test
    func synchronizesManagerWithNilWhenActivityIsRunning() {
        let manager = SpyFeedLiveActivityManager()
        manager.hasRunningActivity = true

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        #expect(manager.synchronizeCalls.count == 1)
        #expect(manager.synchronizeCalls.first == .some(nil))
    }

    @Test
    func endingClearsTheRunningActivity() {
        let manager = SpyFeedLiveActivityManager()
        manager.hasRunningActivity = true

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        // The spy mirrors the manager: a nil synchronize ends the activity.
        #expect(manager.hasRunningActivity == false)
    }

    // MARK: - No activity running

    @Test
    func doesNothingWhenNoActivityIsRunning() {
        let manager = SpyFeedLiveActivityManager()

        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)

        #expect(manager.synchronizeCalls.isEmpty)
    }

    // MARK: - Integration with UpdateFeedLiveActivityUseCase

    @Test
    func allowsSubsequentUpdateToStartAfterReset() throws {
        let manager = SpyFeedLiveActivityManager()
        let child = try Child(name: "Robin", createdBy: UUID())
        let events: [BabyEvent] = [.bottleFeed(try BottleFeedEvent(
            metadata: EventMetadata(childID: child.id, occurredAt: .now, createdBy: UUID()),
            amountMilliliters: 120
        ))]

        // Update starts the activity.
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager
        )
        #expect(manager.hasRunningActivity)

        // Reset ends it.
        ResetFeedLiveActivityUseCase.execute(liveActivityManager: manager)
        #expect(manager.hasRunningActivity == false)
        #expect(manager.synchronizeCalls.last == .some(nil))

        // A later update starts it again.
        UpdateFeedLiveActivityUseCase.execute(
            events: events,
            child: child,
            activeSleep: nil,
            isLiveActivityEnabled: true,
            liveActivityManager: manager
        )
        #expect(manager.hasRunningActivity)
    }
}
