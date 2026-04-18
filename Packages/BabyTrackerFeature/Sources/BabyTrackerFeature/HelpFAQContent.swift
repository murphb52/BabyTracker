import Foundation

public enum HelpFAQContent {
    public static let sections: [HelpFAQSection] = [
        HelpFAQSection(
            title: "Summary, Today, and Trends",
            items: [
                HelpFAQItem(
                    id: "summary-range-picker",
                    title: "How do Today and Trends work in Summary?",
                    answer: "The Summary tab has two views. Today focuses on the current day, while Trends groups recent history into 7 Days, 30 Days, or All Time for the selected child."
                ),
                HelpFAQItem(
                    id: "summary-more-information",
                    title: "What is More Information in Summary?",
                    answer: "More Information opens the detailed summary screen. It breaks metrics into feeds, sleep, nappies, and activity, and it can also show one specific day's numbers when you switch from Range to Day."
                ),
                HelpFAQItem(
                    id: "summary-streaks-averages",
                    title: "How are streaks and averages calculated?",
                    answer: "The logging streak counts consecutive days with at least one saved event. Trends averages use only the events inside the current range, so they change when you pick 7 Days, 30 Days, All Time, or a specific day in More Information."
                ),
            ]
        ),
        HelpFAQSection(
            title: "Feed, Sleep, and Nappy Trends",
            items: [
                HelpFAQItem(
                    id: "feeds",
                    title: "What counts as a feed?",
                    answer: "Breast feeds and bottle feeds both count as feeds. Bottle volume averages use bottle feeds only, while feed totals include both types."
                ),
                HelpFAQItem(
                    id: "sleep",
                    title: "How should I read the sleep metrics?",
                    answer: "Today and Trends include sleep that overlaps the selected period, including an active session up to now. In More Information, average and longest-block values use completed sleep sessions."
                ),
                HelpFAQItem(
                    id: "nappies",
                    title: "How are nappy trends grouped?",
                    answer: "Nappy trends are grouped by the type you log: wet, dirty, mixed, or dry. The Summary view is meant to help you review what was recorded, not to interpret whether a pattern is normal."
                ),
            ]
        ),
        HelpFAQSection(
            title: "Sharing and Caregiver Access",
            items: [
                HelpFAQItem(
                    id: "sharing",
                    title: "How does caregiver sharing work?",
                    answer: "Sharing uses iCloud so another caregiver can work from the same child timeline. If sharing is unavailable, local data still stays on the device and you can review sync details from Profile > Sharing & Caregivers or Profile > App Settings > Sync Status."
                ),
                HelpFAQItem(
                    id: "switching-children",
                    title: "What happens when I switch children?",
                    answer: "When you choose a different child, the app resets back to that child's Profile tab so you can confirm you are looking at the right profile before logging or reviewing events."
                ),
            ]
        ),
        HelpFAQSection(
            title: "Exporting and Talking to a Clinician",
            items: [
                HelpFAQItem(
                    id: "export-data",
                    title: "How do I export data?",
                    answer: "Open Profile > App Settings > Export Data to prepare a file you can share. Export gives you the recorded information for the selected child so you can keep a copy or bring it into another workflow."
                ),
                HelpFAQItem(
                    id: "clinician",
                    title: "Can I use this data when talking to a clinician?",
                    answer: "Yes. The app can help you share logged details and trends during a conversation with a clinician, but it does not diagnose conditions or tell you what a pattern means medically."
                ),
            ]
        ),
    ]
}
