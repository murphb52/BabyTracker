import Foundation

public struct HelpFAQSection: Equatable, Sendable {
    public let title: String
    public let items: [HelpFAQItem]

    public init(title: String, items: [HelpFAQItem]) {
        self.title = title
        self.items = items
    }
}

public struct HelpFAQItem: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let answer: String

    public init(id: String, title: String, answer: String) {
        self.id = id
        self.title = title
        self.answer = answer
    }
}
