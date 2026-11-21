import FoundationModels

struct DailyPatternTool: Tool {
    let name = "findDailyPattern"
    let description = "Finds the times of day an event usually happens, for example when naps usually start or when feeds cluster."

    let dataSource: AssistantDataSource

    @Generable
    struct Arguments {
        @Guide(description: "The kind of event to look for a pattern in")
        var category: EventCategoryArgument
        @Guide(description: "How far back to look. last7Days or last30Days work best.")
        var period: PeriodArgument
    }

    func call(arguments: Arguments) async throws -> String {
        try await dataSource.patternText(
            category: arguments.category.domainValue,
            period: arguments.period.domainValue
        )
    }
}
