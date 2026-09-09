# 109 Onboarding Character Layout Revamp

## Goal

Revamp onboarding so every step feels visually consistent and stable while adding a small animated character vignette that reflects each page's content.

## Approach

1. Add a reusable SwiftUI character scene for onboarding pages.
   - Keep it lightweight and local to the onboarding presentation layer.
   - Use simple SwiftUI animation instead of adding video asset management or playback complexity.
   - Provide variants that match the page topic, such as quick logging, timeline, charts, notifications, profile setup, baby setup, and app preview.
2. Update intro and demo onboarding page wrappers to show the character scene above each page's title and body copy.
3. Update setup and interactive steps so the same character treatment appears on every onboarding page.
4. Make the interactive onboarding layout reserve a consistent content area between the top bar and footer.
   - Keep the footer pinned so Continue and setup buttons do not jump between steps.
   - Allow individual step content to scroll inside the reserved area when needed.
5. Keep changes focused on onboarding presentation and preserve existing flow behavior.
6. Build and run relevant package tests before committing.

## Acceptance criteria

1. Every interactive onboarding page includes an animated character scene that represents the step content.
2. The footer buttons remain in a stable vertical position as users move between onboarding pages.
3. Existing onboarding actions and skip behavior continue to work.
4. Relevant previews remain present for touched SwiftUI views.
5. The implementation avoids unnecessary abstraction and does not introduce video playback dependencies.

- [x] Complete
