import Foundation

struct OnboardingIntroPage: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let symbolNames: [String]
    let actionTitle: String?
    let actionSymbolName: String?
    let highlights: [OnboardingIntroHighlight]
}
