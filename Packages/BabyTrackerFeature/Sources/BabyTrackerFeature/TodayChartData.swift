import Foundation

/// Hourly cumulative chart series for all four tracked categories in the Today tab.
public struct TodayChartData: Equatable, Sendable {
    /// Cumulative mL of bottle feed consumed per hour.
    public let bottle: HourlyCumulativeSeries

    /// Cumulative mL of formula bottle feed consumed per hour.
    public let bottleFormula: HourlyCumulativeSeries

    /// Cumulative mL of breast milk bottle feed consumed per hour.
    public let bottleBreastMilk: HourlyCumulativeSeries

    /// Cumulative mL of mixed bottle feed consumed per hour.
    public let bottleMixed: HourlyCumulativeSeries

    /// Cumulative mL of formula-inclusive bottle feed consumed per hour (formula + mixed).
    public let bottleFormulaIncludingMixed: HourlyCumulativeSeries

    /// Cumulative mL of breast-milk-inclusive bottle feed consumed per hour (breast milk + mixed).
    public let bottleBreastMilkIncludingMixed: HourlyCumulativeSeries

    /// Cumulative breast-feed session count per hour.
    public let breast: HourlyCumulativeSeries

    /// Cumulative minutes of completed sleep per hour.
    public let sleep: HourlyCumulativeSeries

    /// Cumulative nappy change count per hour.
    public let nappy: HourlyCumulativeSeries

    /// Cumulative pee-only nappy count per hour.
    public let nappyPee: HourlyCumulativeSeries

    /// Cumulative poo-only nappy count per hour.
    public let nappyPoo: HourlyCumulativeSeries

    /// Cumulative mixed nappy count per hour.
    public let nappyMixed: HourlyCumulativeSeries

    /// Cumulative pee-inclusive nappy count per hour (pee + mixed).
    public let nappyPeeIncludingMixed: HourlyCumulativeSeries

    /// Cumulative poo-inclusive nappy count per hour (poo + mixed).
    public let nappyPooIncludingMixed: HourlyCumulativeSeries

    public init(
        bottle: HourlyCumulativeSeries,
        bottleFormula: HourlyCumulativeSeries,
        bottleBreastMilk: HourlyCumulativeSeries,
        bottleMixed: HourlyCumulativeSeries,
        bottleFormulaIncludingMixed: HourlyCumulativeSeries,
        bottleBreastMilkIncludingMixed: HourlyCumulativeSeries,
        breast: HourlyCumulativeSeries,
        sleep: HourlyCumulativeSeries,
        nappy: HourlyCumulativeSeries,
        nappyPee: HourlyCumulativeSeries,
        nappyPoo: HourlyCumulativeSeries,
        nappyMixed: HourlyCumulativeSeries,
        nappyPeeIncludingMixed: HourlyCumulativeSeries,
        nappyPooIncludingMixed: HourlyCumulativeSeries
    ) {
        self.bottle = bottle
        self.bottleFormula = bottleFormula
        self.bottleBreastMilk = bottleBreastMilk
        self.bottleMixed = bottleMixed
        self.bottleFormulaIncludingMixed = bottleFormulaIncludingMixed
        self.bottleBreastMilkIncludingMixed = bottleBreastMilkIncludingMixed
        self.breast = breast
        self.sleep = sleep
        self.nappy = nappy
        self.nappyPee = nappyPee
        self.nappyPoo = nappyPoo
        self.nappyMixed = nappyMixed
        self.nappyPeeIncludingMixed = nappyPeeIncludingMixed
        self.nappyPooIncludingMixed = nappyPooIncludingMixed
    }
}
