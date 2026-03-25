import BabyTrackerDomain
import SwiftUI

public enum BabyEventStyle {
    public static func systemImage(for kind: BabyEventKind) -> String {
        BabyEventPresentation.systemImage(for: kind)
    }

    public static func accentColor(for kind: BabyEventKind) -> Color {
        switch kind {
        case .breastFeed:
            Color(red: 0.84, green: 0.29, blue: 0.42)
        case .bottleFeed:
            Color(red: 0.15, green: 0.56, blue: 0.72)
        case .sleep:
            Color(red: 0.29, green: 0.33, blue: 0.73)
        case .nappy:
            Color(red: 0.74, green: 0.47, blue: 0.16)
        }
    }

    public static func backgroundColor(for kind: BabyEventKind) -> Color {
        accentColor(for: kind).opacity(0.14)
    }

    public static func cardFillColor(for kind: BabyEventKind) -> Color {
        switch kind {
        case .breastFeed:
            Color(red: 0.98, green: 0.93, blue: 0.95)
        case .bottleFeed:
            Color(red: 0.92, green: 0.97, blue: 0.98)
        case .sleep:
            Color(red: 0.93, green: 0.94, blue: 0.99)
        case .nappy:
            Color(red: 0.98, green: 0.95, blue: 0.91)
        }
    }

    public static func timelineFillColor(for kind: BabyEventKind) -> Color {
        accentColor(for: kind)
    }

    public static func timelineBorderColor(for kind: BabyEventKind) -> Color {
        accentColor(for: kind).opacity(0.8)
    }
}
