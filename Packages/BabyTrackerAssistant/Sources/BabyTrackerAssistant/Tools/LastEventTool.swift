import FoundationModels

struct LastEventTool: Tool {
    let name = "getLastEvent"
    let description = "Finds the most recent logged event of a kind and how long ago it was. Use for questions like 'when did she last feed?'."

    let dataSource: AssistantDataSource

    @Generable
    struct Arguments {
        @Guide(description: "The kind of event to look up")
        var category: EventCategoryArgument
    }

    func call(arguments: Arguments) async throws -> String {
        try await dataSource.lastEventText(category: arguments.category.domainValue)
    }
}
