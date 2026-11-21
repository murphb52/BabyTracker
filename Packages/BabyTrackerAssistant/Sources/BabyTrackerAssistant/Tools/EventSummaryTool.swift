import FoundationModels

struct EventSummaryTool: Tool {
    let name = "summarizeEvents"
    let description = "Counts and totals one kind of event over a period, such as feeds today, sleep yesterday or nappies in the last 7 days."

    let dataSource: AssistantDataSource

    @Generable
    struct Arguments {
        @Guide(description: "The kind of event to total")
        var category: EventCategoryArgument
        @Guide(description: "The period to total over")
        var period: PeriodArgument
    }

    func call(arguments: Arguments) async throws -> String {
        try await dataSource.summaryText(
            category: arguments.category.domainValue,
            period: arguments.period.domainValue
        )
    }
}
