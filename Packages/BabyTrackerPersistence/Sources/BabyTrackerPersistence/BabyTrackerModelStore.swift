import Foundation
import SwiftData

public final class BabyTrackerModelStore {
    public let modelContainer: ModelContainer

    public init(isStoredInMemoryOnly: Bool = false) throws {
        let schema = Schema([
            StoredUserIdentity.self,
            StoredChild.self,
            StoredMembership.self,
            StoredBreastFeedEvent.self,
            StoredBottleFeedEvent.self,
            StoredSleepEvent.self,
            StoredNappyEvent.self,
            StoredCloudKitRecordMetadata.self,
            StoredSyncAnchor.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )

        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
