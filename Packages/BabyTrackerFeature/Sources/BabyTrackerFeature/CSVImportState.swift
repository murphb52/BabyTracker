import BabyTrackerDomain
import Foundation

public enum CSVImportState: Equatable, Sendable {
    case idle
    case previewing(ImportPreviewState)
    case importing
    case complete(CSVImportResult)
    case error(String)
}
