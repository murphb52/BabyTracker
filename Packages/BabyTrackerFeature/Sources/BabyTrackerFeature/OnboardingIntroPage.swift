import Foundation

struct OnboardingIntroPage: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let symbolNames: [String]
    let highlights: [OnboardingIntroHighlight]
}
