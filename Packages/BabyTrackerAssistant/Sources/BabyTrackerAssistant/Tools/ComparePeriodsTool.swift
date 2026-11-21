import FoundationModels

struct ComparePeriodsTool: Tool {
    let name = "comparePeriods"
    let description = "Compares one kind of event between two periods, for example this week against last week, and reports the change in daily averages."

    let dataSource: AssistantDataSource

    @Generable
    struct Arguments {
        @Guide(description: "The kind of event to compare")
        var category: EventCategoryArgument
        @Guide(description: "The more recent period, for example last7Days or today")
        var currentPeriod: PeriodArgument
        @Guide(description: "The earlier period to compare against, for example previous7Days or yesterday")
        var earlierPeriod: PeriodArgument
    }

    func call(arguments: Arguments) async throws -> String {
        try await dataSource.comparisonText(
            category: arguments.category.domainValue,
            currentPeriod: arguments.currentPeriod.domainValue,
            earlierPeriod: arguments.earlierPeriod.domainValue
        )
    }
}
