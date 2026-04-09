import BabyTrackerFeature
import Testing

struct HelpFAQContentTests {
    @Test
    func faqContentCoversCurrentSummarySharingAndExportTopics() {
        let titles = HelpFAQContent.sections.map(\.title)

        #expect(titles.contains("Summary, Today, and Trends"))
        #expect(titles.contains("Sharing and Caregiver Access"))
        #expect(titles.contains("Exporting and Talking to a Clinician"))
    }

    @Test
    func faqItemsUseCurrentNavigationAndSummaryTerminology() {
        let answers = HelpFAQContent.sections
            .flatMap(\.items)
            .map(\.answer)
            .joined(separator: " ")

        #expect(answers.contains("Today"))
        #expect(answers.contains("Trends"))
        #expect(answers.contains("More Information"))
        #expect(answers.contains("Sharing & Caregivers"))
        #expect(answers.contains("App Settings > Export Data"))
    }
}
