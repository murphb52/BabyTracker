import BabyTrackerDomain
import Foundation

public enum NestImportState: Equatable, Sendable {
    case idle
    case previewing(ImportPreviewState)
    case importing(ImportProgress)
    case complete(CSVImportResult)
    case error(String)
}
