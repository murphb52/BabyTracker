# 029 FAQ & Help Section

## Goal
Add a focused FAQ and Help area that is reachable from Profile and answers the most common product questions without forcing parents to leave the app.

## Scope
1. Add a new help entry point from the Profile tab.
2. Create a simple FAQ screen with grouped questions and expandable answers.
3. Cover the highest-value topics first:
   - what the summary metrics mean
   - how feed, sleep, and nappy trends should be read
   - what sharing does
   - how to export or discuss data with a doctor
4. Keep the content educational and product-specific, not medical advice.

## Notes
- The current Profile experience lives under `ChildProfileView` and related detail/settings screens.
- The summary tab already shows top metrics and trends, so the help content should explain those surfaces using the app's actual terminology.
- Any medical framing should stay careful and neutral. The app can explain what a metric represents, but should not imply diagnosis.

## Plan
1. Review the current Profile navigation and choose the simplest place to add a Help or FAQ row.
2. Define a small FAQ model in the feature layer for grouped help content.
3. Build a SwiftUI FAQ screen that supports:
   - grouped sections
   - tappable expand and collapse rows
   - readable long-form answer text
4. Write initial answers for the most likely user questions:
   - what counts as a feed
   - what the summary range picker changes
   - how streaks and averages are calculated at a high level
   - how caregiver sharing works
   - how exported information can be shown to a clinician
5. Add short disclaimers where the copy touches health interpretation.
6. Add tests for any new help view state or content model if that layer is introduced.
7. Run targeted validation for navigation and accessibility.

## Acceptance Criteria
1. The Profile area exposes a clear Help or FAQ entry point.
2. Users can read answers in-app without needing external documentation.
3. FAQ content matches the app's actual current features and labels.
4. Content explains metrics and sharing behavior clearly but does not present medical advice as fact.
5. The screen remains readable with Dynamic Type and works with VoiceOver.

## Out of Scope
1. Remote CMS-backed help content.
2. Live chat, support tickets, or web-hosted documentation systems.
3. Medical recommendations or diagnostic guidance.

- [ ] Complete
