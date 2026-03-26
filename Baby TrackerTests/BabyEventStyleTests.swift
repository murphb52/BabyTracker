import BabyTrackerDomain
import BabyTrackerFeature
import SwiftUI
import Testing
import UIKit

@MainActor
struct BabyEventStyleTests {
    @Test
    func prominentEventSurfacesMaintainReadableContrastAcrossAppearances() {
        for kind in [BabyEventKind.breastFeed, .bottleFeed, .sleep, .nappy] {
            let fill = UIColor(BabyEventStyle.buttonFillColor(for: kind))
            let foreground = UIColor(BabyEventStyle.buttonForegroundColor(for: kind))

            #expect(contrastRatio(between: fill, and: foreground, style: .light) >= 4.5)
            #expect(contrastRatio(between: fill, and: foreground, style: .dark) >= 4.5)
        }
    }

    @Test
    func eventCardsMaintainReadableContrastAcrossAppearances() {
        for kind in [BabyEventKind.breastFeed, .bottleFeed, .sleep, .nappy] {
            let fill = UIColor(BabyEventStyle.cardFillColor(for: kind))
            let foreground = UIColor(BabyEventStyle.cardForegroundColor(for: kind))
            let secondaryForeground = UIColor(BabyEventStyle.cardSecondaryForegroundColor(for: kind))

            #expect(contrastRatio(between: fill, and: foreground, style: .light) >= 4.5)
            #expect(contrastRatio(between: fill, and: foreground, style: .dark) >= 4.5)
            #expect(contrastRatio(between: fill, and: secondaryForeground, style: .light) >= 3.0)
            #expect(contrastRatio(between: fill, and: secondaryForeground, style: .dark) >= 3.0)
        }
    }

    private func contrastRatio(
        between background: UIColor,
        and foreground: UIColor,
        style: UIUserInterfaceStyle
    ) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: style)
        let backgroundLuminance = relativeLuminance(for: background.resolvedColor(with: traits))
        let foregroundLuminance = relativeLuminance(for: foreground.resolvedColor(with: traits))
        let lighter = max(backgroundLuminance, foregroundLuminance)
        let darker = min(backgroundLuminance, foregroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private func relativeLuminance(for color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))

        let linearRed = linearize(red)
        let linearGreen = linearize(green)
        let linearBlue = linearize(blue)

        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }

    private func linearize(_ component: CGFloat) -> Double {
        let value = Double(component)
        if value <= 0.03928 {
            return value / 12.92
        }

        return pow((value + 0.055) / 1.055, 2.4)
    }
}
