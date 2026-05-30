import Foundation

/// Seed data and age-based defaults for the medication editor.
public enum MedicationCatalog {
    /// Common children's medicines surfaced as quick-pick chips before any history exists.
    /// History-derived names take precedence and are de-duplicated against this list.
    public static let commonMedicines: [String] = [
        "Paracetamol (Calpol)",
        "Ibuprofen (Nurofen)",
        "Vitamin D drops",
        "Gripe water",
        "Teething gel"
    ]

    /// Default ml quick-pick amounts, chosen by the child's age. These are defaults only;
    /// history-based smart suggestions are surfaced ahead of them by the UI.
    public static func defaultMillilitreAmounts(
        forBirthDate birthDate: Date?,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> [Double] {
        guard let birthDate else { return [2.5, 5, 7.5, 10] }
        let months = calendar.dateComponents([.month], from: birthDate, to: referenceDate).month ?? 12
        if months < 12 {
            return [1, 2.5, 5]
        }
        if months < 48 {
            return [2.5, 5, 7.5, 10]
        }
        return [5, 10, 15, 20]
    }
}
