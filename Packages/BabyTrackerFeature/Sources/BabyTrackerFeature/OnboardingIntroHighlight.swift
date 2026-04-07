import Foundation

struct OnboardingIntroHighlight: Identifiable, Equatable, Sendable {
    let title: String
    let symbolName: String

    var id: String {
        "\(symbolName)-\(title)"
    }
}
