import BabyTrackerDomain
import Foundation

public enum CSVImportState: Equatable, Sendable {
    case idle
    case previewing(CSVParseResult)
    case importing
    case complete(CSVImportResult)
    case error(String)
}
