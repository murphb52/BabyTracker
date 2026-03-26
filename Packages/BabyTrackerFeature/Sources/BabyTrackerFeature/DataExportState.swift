import Foundation

public enum DataExportState: Sendable {
    case idle
    case exporting
    case ready(URL)
    case error(String)
}
