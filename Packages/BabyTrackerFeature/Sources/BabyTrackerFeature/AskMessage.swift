import Foundation

/// One line in the Ask conversation. Messages are only kept in memory.
public struct AskMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let kind: AskMessageKind
    public let text: String

    public init(id: UUID = UUID(), kind: AskMessageKind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}
