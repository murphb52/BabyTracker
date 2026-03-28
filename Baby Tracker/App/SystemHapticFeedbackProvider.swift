import BabyTrackerDomain
import UIKit

@MainActor
final class SystemHapticFeedbackProvider: HapticFeedbackProviding {
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)

    init() {
        prepareGenerators()
    }

    func play(_ event: HapticEvent) {
        switch event {
        case .actionSucceeded:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        case .actionFailed:
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
        case .selectionChanged:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .destructiveActionConfirmed:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        case .sleepStarted, .sleepEnded:
            mediumImpactGenerator.impactOccurred()
            mediumImpactGenerator.prepare()
        }
    }

    private func prepareGenerators() {
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        mediumImpactGenerator.prepare()
    }
}
