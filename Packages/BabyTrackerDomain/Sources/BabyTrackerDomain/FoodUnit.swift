import Foundation

public enum FoodUnit: String, CaseIterable, Codable, Equatable, Sendable {
    case millilitres
    case grams
    case teaspoons
    case tablespoons
    case bowl
    case pouch
    case piece
    case custom

    public var pickerTitle: String {
        switch self {
        case .millilitres: "ml"
        case .grams: "g"
        case .teaspoons: "tsp"
        case .tablespoons: "tbsp"
        case .bowl: "bowl"
        case .pouch: "pouch"
        case .piece: "piece"
        case .custom: "custom"
        }
    }

    public func displayTitle(amount: Double, customLabel: String? = nil) -> String {
        switch self {
        case .millilitres: "ml"
        case .grams: "g"
        case .teaspoons: "tsp"
        case .tablespoons: "tbsp"
        case .bowl: amount == 1 ? "bowl" : "bowls"
        case .pouch: amount == 1 ? "pouch" : "pouches"
        case .piece: amount == 1 ? "piece" : "pieces"
        case .custom:
            customLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "unit"
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
