# 052 Release Submission Prep

Prepare Baby Tracker for App Store submission by cleaning the remaining release-facing UI and diagnostics, adding the app privacy manifest, and creating the submission copy needed for App Review and App Store Connect.

Related issue: #174

1. Remove internal milestone and placeholder language from reachable shipping UI.
2. Add `PrivacyInfo.xcprivacy` for the app's current first-party required-reason API usage.
3. Remove current Release build warnings without changing behavior.
4. Remove raw `print` diagnostics from release code paths while keeping structured logging.
5. Add support and privacy policy documents that can back temporary GitHub-hosted URLs.
6. Add markdown documents for App Review notes and App Store Connect metadata, including realistic copy aligned with the shipped feature set.
7. Verify the Release build is warning-free and the unit test plan still passes.

- [x] Complete
