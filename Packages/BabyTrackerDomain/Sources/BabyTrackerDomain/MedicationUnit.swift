import Foundation

/// The unit a medication dose is measured in.
///
/// `custom` is paired with a free-text label on ``MedicationEvent`` (`customUnitLabel`),
/// mirroring how `MilkType.other` carries no associated value and relies on a sibling field.
public enum MedicationUnit: String, CaseIterable, Codable, Sendable {
    case ml
    case mg
    case drops
    case tablet
    case custom

    /// Long-form title used in pickers.
    public var title: String {
        switch self {
        case .ml:
            "Millilitres (ml)"
        case .mg:
            "Milligrams (mg)"
        case .drops:
            "Drops"
        case .tablet:
            "Tablets / capsules"
        case .custom:
            "Custom"
        }
    }

    /// Compact title appended after a dose amount (e.g. "5 ml").
    public var shortTitle: String {
        switch self {
        case .ml:
            "ml"
        case .mg:
            "mg"
        case .drops:
            "drops"
        case .tablet:
            "tablet(s)"
        case .custom:
            "unit"
        }
    }
}
