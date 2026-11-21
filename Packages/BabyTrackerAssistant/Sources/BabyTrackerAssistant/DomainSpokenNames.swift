import BabyTrackerDomain
import Foundation

// Plain-English names used in tool output. They live here rather than in
// the domain because they exist only to phrase text for the language model.

extension EventSummaryCategory {
    var spokenName: String {
        switch self {
        case .feeds: "feeds"
        case .sleep: "sleeps"
        case .nappies: "nappy changes"
        case .food: "food entries"
        case .medication: "medication doses"
        case .bath: "baths"
        }
    }
}

extension RelativePeriod {
    var includesToday: Bool {
        switch self {
        case .today, .last7Days, .last30Days: true
        case .yesterday, .previous7Days, .previous30Days: false
        }
    }
}

extension NappyType {
    var spokenName: String {
        switch self {
        case .dry: "dry"
        case .wee: "wet"
        case .poo: "dirty"
        case .mixed: "wet and dirty"
        }
    }
}

extension MilkType {
    var spokenName: String {
        switch self {
        case .breastMilk: "breast milk"
        case .formula: "formula"
        case .mixed: "mixed milk"
        case .other: "other milk"
        }
    }
}

extension BreastSide {
    var spokenName: String {
        switch self {
        case .left: "left side"
        case .right: "right side"
        case .both: "both sides"
        }
    }
}

extension String {
    var capitalizedFirstLetter: String {
        prefix(1).uppercased() + dropFirst()
    }
}
