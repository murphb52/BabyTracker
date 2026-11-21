# 115 - Ask Tab: On-Device AI Questions Over Baby Data

GitHub issue: #291

## Goal

Let caregivers ask plain-language questions about their child and get answers based on the data they have logged. For example:

- "When did she last feed?"
- "How many wet nappies today?"
- "Is he sleeping more this week than last week?"
- "What time does she usually nap?"
- "Is this many feeds normal?" (hedged, general guidance only)

The answers come from Apple's on-device **Foundation Models** framework (iOS 26). This means no backend, no API keys, and no data leaving the phone.

## Constraints that shape the design

- **Small context window (~4K tokens).** Raw history is never put into the prompt. The model fetches what it needs through **tool calling**.
- **Weak at maths over long lists.** Every count, total, average and comparison is calculated in Swift domain code. The model only chooses tools and writes the reply.
- **Device-gated.** It needs Apple Intelligence hardware with Apple Intelligence turned on. The tab is hidden whenever `SystemLanguageModel.default.availability` is not `.available`.

## Decisions

- Data access is through tool calling.
- All event types are covered: feeds (breast and bottle), sleep, nappies, food, medication and bath.
- Question types: factual lookups, trends and comparisons, daily patterns, and hedged "is this normal" advice.
- It lives in a new **Ask** tab. The chat is ephemeral: nothing is saved and there is no CloudKit change.
- The empty state shows suggested question chips.
- It is on for every eligible device. There is no beta toggle.
- Advice must stay broad and point to a GP or health visitor. Every answer carries a fixed disclaimer.

## Approach

### Domain (`BabyTrackerDomain`, framework-free)

1. `ChildQuestionAnswering` protocol:
   - `availability`
   - `answer(_:for:)` (async)
   - `resetConversation()`
2. Supporting types:
   - `AssistantAvailability`
   - `AssistantAnswer`
   - `AssistantError`
3. Query types:
   - `EventSummaryCategory`: feeds, sleep, nappies, food, medication, bath. Each one maps to `BabyEventKind`s.
   - `RelativePeriod`: today, yesterday, last 7 days, previous 7 days, last 30 days, previous 30 days. Resolves to a `DateInterval` from `now` and a `Calendar`, so dates are never left to the model.
4. Use cases, built on `EventRepository.loadTimeline`. They ignore deleted events and use the same minute rules as `SummaryMetricsCalculator`, so answers match the Summary tab.
   - `FetchLastEventUseCase`: latest event in a category.
   - `SummarizeEventsInRangeUseCase`: count, daily average, and category totals:
     - bottle millilitres and breast minutes
     - sleep minutes and the longest sleep
     - nappy types
     - food and medicine names
   - `FindDailyPatternUseCase`: hour-of-day counts over a period.

A comparison doesn't need its own use case. The comparison tool runs two summaries and states the difference, using numbers computed in Swift.

### Assistant package (`BabyTrackerAssistant`, new)

This is the only package that imports `FoundationModels`.

- `AssistantDataSource`: a `@MainActor` class wrapping the use cases for one child, so tools stay `Sendable`.
- Tools:
  - `LastEventTool`
  - `EventSummaryTool`
  - `ComparePeriodsTool`
  - `DailyPatternTool`
  
  Arguments are `@Generable` with `@Guide` descriptions, and each tool returns compact text.
- `AssistantInstructions`:
  - include the child's name, age and the current date and time
  - answer only from tool results and never guess numbers
  - keep replies short
  - advice is broad and hedged, never a diagnosis
  - urgent symptoms → contact a medical professional now
- `FoundationModelsQuestionAnswerer`: keeps one `LanguageModelSession` per child. It starts a new session when the child changes, or when the context window is exceeded.

### Feature (`BabyTrackerFeature`)

- `ChildWorkspaceTab.ask`. The tab only appears when the answerer reports `.available`.
- `AskViewModel` holds the ephemeral messages, the loading and error state, and the suggested questions. It depends only on `ChildQuestionAnswering`.
- Views, each with a `#Preview`:
  - `AskView`
  - `AskMessageBubbleView`
  - `AskSuggestedQuestionsView`
  - `AskDisclaimerFooterView`

### App

- `AppContainer` builds `FoundationModelsQuestionAnswerer` and passes it to `AppModel`.
- Previews and tests use `UnavailableQuestionAnswerer`, so the tab is hidden for them.

## Out of scope (v1)

- cloud fallback
- saved chat history
- curated medical reference ranges
- auto-generated daily digest
- streaming responses

## Testing

- Domain: tests for `RelativePeriod`, the summary, the last event and the daily pattern. They cover range edges and deleted events.
- Assistant: tool output formatting from the data source, without running the model.
- Feature: `AskViewModel` state changes, using a fake answerer.
- Manual, on an Apple Intelligence device:
  - ask one question from each category and check the numbers against the Summary tab
  - turn Apple Intelligence off and confirm the tab disappears

- [ ] Complete
