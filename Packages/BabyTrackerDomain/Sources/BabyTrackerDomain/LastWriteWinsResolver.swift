import Foundation

public enum LastWriteWinsResolver {
    public static func prefersLocal(
        _ local: EventMetadata,
        over remote: EventMetadata
    ) -> Bool {
        if local.updatedAt != remote.updatedAt {
            return local.updatedAt > remote.updatedAt
        }

        let localUpdater = local.updatedBy.uuidString
        let remoteUpdater = remote.updatedBy.uuidString

        if localUpdater != remoteUpdater {
            return localUpdater > remoteUpdater
        }

        return local.id.uuidString >= remote.id.uuidString
    }
}
