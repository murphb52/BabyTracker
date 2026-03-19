import Foundation

extension String {
    func trimmedForProfileField() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
