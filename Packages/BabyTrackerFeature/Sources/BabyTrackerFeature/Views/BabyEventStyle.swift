import BabyTrackerDomain
import SwiftUI
import UIKit

public enum BabyEventStyle {
    public static func systemImage(for kind: BabyEventKind) -> String {
        BabyEventPresentation.systemImage(for: kind)
    }

    public static func accentColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).accent
    }

    public static func backgroundColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).badgeFill
    }

    public static func cardFillColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).cardFill
    }

    public static func cardForegroundColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).cardForeground
    }

    public static func cardSecondaryForegroundColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).cardSecondaryForeground
    }

    public static func timelineFillColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).prominentFill
    }

    public static func timelineForegroundColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).prominentForeground
    }

    public static func timelineBorderColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).prominentBorder
    }

    public static func buttonFillColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).prominentFill
    }

    public static func buttonForegroundColor(for kind: BabyEventKind) -> Color {
        palette(for: kind).prominentForeground
    }

    private static func palette(for kind: BabyEventKind) -> EventPalette {
        switch kind {
        case .breastFeed:
            EventPalette(
                accent: adaptiveColor(light: rgb(0.84, 0.29, 0.42), dark: rgb(1.00, 0.61, 0.72)),
                badgeFill: adaptiveColor(light: rgba(0.84, 0.29, 0.42, 0.14), dark: rgba(0.84, 0.29, 0.42, 0.28)),
                cardFill: adaptiveColor(light: rgb(0.98, 0.93, 0.95), dark: rgb(0.31, 0.13, 0.20)),
                cardForeground: adaptiveColor(light: rgb(0.31, 0.13, 0.20), dark: rgb(0.99, 0.95, 0.97)),
                cardSecondaryForeground: adaptiveColor(light: rgb(0.47, 0.25, 0.31), dark: rgb(0.94, 0.81, 0.86)),
                prominentFill: adaptiveColor(light: rgb(0.72, 0.18, 0.32), dark: rgb(0.62, 0.21, 0.32)),
                prominentForeground: adaptiveColor(light: rgb(1.00, 1.00, 1.00), dark: rgb(1.00, 0.97, 0.98)),
                prominentBorder: adaptiveColor(light: rgba(0.84, 0.29, 0.42, 0.82), dark: rgba(1.00, 0.61, 0.72, 0.72))
            )
        case .bottleFeed:
            EventPalette(
                accent: adaptiveColor(light: rgb(0.15, 0.56, 0.72), dark: rgb(0.51, 0.84, 0.96)),
                badgeFill: adaptiveColor(light: rgba(0.15, 0.56, 0.72, 0.14), dark: rgba(0.15, 0.56, 0.72, 0.28)),
                cardFill: adaptiveColor(light: rgb(0.92, 0.97, 0.98), dark: rgb(0.09, 0.21, 0.28)),
                cardForeground: adaptiveColor(light: rgb(0.08, 0.29, 0.38), dark: rgb(0.95, 0.98, 0.99)),
                cardSecondaryForeground: adaptiveColor(light: rgb(0.16, 0.40, 0.49), dark: rgb(0.78, 0.89, 0.94)),
                prominentFill: adaptiveColor(light: rgb(0.07, 0.44, 0.58), dark: rgb(0.11, 0.39, 0.49)),
                prominentForeground: adaptiveColor(light: rgb(1.00, 1.00, 1.00), dark: rgb(0.95, 0.99, 1.00)),
                prominentBorder: adaptiveColor(light: rgba(0.15, 0.56, 0.72, 0.82), dark: rgba(0.51, 0.84, 0.96, 0.72))
            )
        case .sleep:
            EventPalette(
                accent: adaptiveColor(light: rgb(0.29, 0.33, 0.73), dark: rgb(0.63, 0.69, 0.99)),
                badgeFill: adaptiveColor(light: rgba(0.29, 0.33, 0.73, 0.14), dark: rgba(0.29, 0.33, 0.73, 0.28)),
                cardFill: adaptiveColor(light: rgb(0.93, 0.94, 0.99), dark: rgb(0.14, 0.17, 0.35)),
                cardForeground: adaptiveColor(light: rgb(0.17, 0.20, 0.47), dark: rgb(0.96, 0.97, 1.00)),
                cardSecondaryForeground: adaptiveColor(light: rgb(0.29, 0.31, 0.56), dark: rgb(0.83, 0.87, 0.98)),
                prominentFill: adaptiveColor(light: rgb(0.23, 0.28, 0.62), dark: rgb(0.21, 0.25, 0.57)),
                prominentForeground: adaptiveColor(light: rgb(1.00, 1.00, 1.00), dark: rgb(0.96, 0.97, 1.00)),
                prominentBorder: adaptiveColor(light: rgba(0.29, 0.33, 0.73, 0.82), dark: rgba(0.63, 0.69, 0.99, 0.74))
            )
        case .nappy:
            EventPalette(
                accent: adaptiveColor(light: rgb(0.74, 0.47, 0.16), dark: rgb(0.96, 0.77, 0.46)),
                badgeFill: adaptiveColor(light: rgba(0.74, 0.47, 0.16, 0.14), dark: rgba(0.74, 0.47, 0.16, 0.30)),
                cardFill: adaptiveColor(light: rgb(0.98, 0.95, 0.91), dark: rgb(0.28, 0.19, 0.08)),
                cardForeground: adaptiveColor(light: rgb(0.39, 0.24, 0.07), dark: rgb(1.00, 0.97, 0.92)),
                cardSecondaryForeground: adaptiveColor(light: rgb(0.53, 0.35, 0.14), dark: rgb(0.95, 0.85, 0.68)),
                prominentFill: adaptiveColor(light: rgb(0.56, 0.34, 0.06), dark: rgb(0.47, 0.31, 0.11)),
                prominentForeground: adaptiveColor(light: rgb(1.00, 1.00, 1.00), dark: rgb(1.00, 0.98, 0.94)),
                prominentBorder: adaptiveColor(light: rgba(0.74, 0.47, 0.16, 0.82), dark: rgba(0.96, 0.77, 0.46, 0.72))
            )
        }
    }

    private static func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }

    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: 1)
    }

    private static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private struct EventPalette {
        let accent: Color
        let badgeFill: Color
        let cardFill: Color
        let cardForeground: Color
        let cardSecondaryForeground: Color
        let prominentFill: Color
        let prominentForeground: Color
        let prominentBorder: Color
    }
}
