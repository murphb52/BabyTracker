import Foundation

struct OnboardingIntroPage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let title: String
    let message: String
    let symbolName: String
}
