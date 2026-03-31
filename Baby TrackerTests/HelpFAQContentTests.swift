import BabyTrackerFeature
import Testing

struct HelpFAQContentTests {
    @Test
    func faqContentCoversSummarySharingAndExportTopics() {
        let titles = HelpFAQContent.sections.map(\.title)

        #expect(titles.contains("Summary and Ranges"))
        #expect(titles.contains("Sharing and Caregiver Access"))
        #expect(titles.contains("Exporting and Talking to a Clinician"))
    }

    @Test
    func faqItemsUseCurrentSummaryTerminology() {
        let answers = HelpFAQContent.sections
            .flatMap(\.items)
            .map(\.answer)
            .joined(separator: " ")

        #expect(answers.contains("More Information"))
        #expect(answers.contains("specific day"))
        #expect(answers.contains("Export Data"))
    }
}
