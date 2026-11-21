import BabyTrackerDomain
import FoundationModels

// The model fills these enums in. They mirror the domain types, so the model
// can only ask for categories and periods the domain understands.

@Generable
enum EventCategoryArgument {
    case feeds
    case sleep
    case nappies
    case food
    case medication
    case bath

    var domainValue: EventSummaryCategory {
        switch self {
        case .feeds: .feeds
        case .sleep: .sleep
        case .nappies: .nappies
        case .food: .food
        case .medication: .medication
        case .bath: .bath
        }
    }
}

@Generable
enum PeriodArgument {
    case today
    case yesterday
    case last7Days
    case previous7Days
    case last30Days
    case previous30Days

    var domainValue: RelativePeriod {
        switch self {
        case .today: .today
        case .yesterday: .yesterday
        case .last7Days: .last7Days
        case .previous7Days: .previous7Days
        case .last30Days: .last30Days
        case .previous30Days: .previous30Days
        }
    }
}
