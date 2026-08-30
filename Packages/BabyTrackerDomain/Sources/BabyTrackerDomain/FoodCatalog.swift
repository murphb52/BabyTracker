import Foundation

public enum FoodCatalog {
    public static let starterNames = ["Porridge", "Banana", "Yoghurt", "Purée"]

    public static func quickAmounts(for unit: FoodUnit) -> [Double] {
        switch unit {
        case .millilitres: [10, 20, 30, 60]
        case .grams: [10, 20, 30, 50]
        case .teaspoons, .tablespoons: [0.5, 1, 2, 3]
        case .bowl, .pouch, .piece: [0.25, 0.5, 1, 2]
        case .custom: []
        }
    }
}
