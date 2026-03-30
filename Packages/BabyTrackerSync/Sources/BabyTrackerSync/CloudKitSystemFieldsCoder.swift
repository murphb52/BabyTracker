import CloudKit
import Foundation

enum CloudKitSystemFieldsCoder {
    enum CodingError: LocalizedError {
        case failedToDecodeRecord

        var errorDescription: String? {
            switch self {
            case .failedToDecodeRecord:
                "Failed to decode stored CloudKit system fields."
            }
        }
    }

    static func encode(_ record: CKRecord) throws -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: archiver)
        archiver.finishEncoding()
        return archiver.encodedData
    }

    static func decodeRecord(from data: Data) throws -> CKRecord {
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = true
        defer { unarchiver.finishDecoding() }

        guard let record = CKRecord(coder: unarchiver) else {
            throw CodingError.failedToDecodeRecord
        }

        return record
    }
}
