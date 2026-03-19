import CloudKit
import Foundation

public enum CloudKitConfiguration {
    public static let containerIdentifier = "iCloud.com.adappt.BabyTracker"
    public static let childRecordType = "Child"
    public static let userRecordType = "UserIdentity"
    public static let membershipRecordType = "Membership"
    public static let breastFeedRecordType = "BreastFeedEvent"
    public static let bottleFeedRecordType = "BottleFeedEvent"
    public static let sleepRecordType = "SleepEvent"
    public static let nappyRecordType = "NappyEvent"

    public static func container() -> CKContainer {
        CKContainer(identifier: containerIdentifier)
    }
}
