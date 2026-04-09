# App Store Connect Metadata

Last updated: 2026-04-09

This file contains proposed metadata for the Baby Tracker App Store listing.

## Product Positioning

Primary positioning: collaborative baby tracker for shared caregiving across devices.

## Metadata

### App Name

Baby Tracker

### Subtitle

Shared feeding, sleep, and nappy log

### Promotional Text

Keep feeds, sleep, and nappy changes in sync across caregivers with simple logging, helpful summaries, and iCloud-backed sharing.

### Description

Baby Tracker helps caregivers stay aligned through the day with one shared place to log feeds, sleep, and nappy changes.

Track the details that matter:

- breast feeds, bottle feeds, sleep, and nappy changes
- timelines, summaries, and current status at a glance
- multiple child profiles in one app
- optional child photos for quick recognition

Built for shared care:

- iCloud sync across your devices
- caregiver sharing so invited helpers can follow the same child profile
- sync status feedback when iCloud is unavailable

Made to fit real routines:

- quick logging flows for common events
- editable history when plans change
- import and export support for backups and migration
- Live Activities for relevant current status

Baby Tracker is designed for everyday coordination between parents and caregivers. It does not provide medical advice, diagnosis, or treatment guidance.

### Keywords

baby tracker,newborn tracker,feeding,sleep,nappy,diaper,breastfeeding,bottle feed,parenting,caregiver

### What's New

- refined release polish for submission
- improved privacy and submission documentation
- cleanup to release diagnostics and build warnings

### Category

Primary: Medical

Secondary fallback if needed: Lifestyle

### Support URL

https://github.com/murphb52/BabyTracker/blob/main/docs/support.md

### Privacy Policy URL

https://github.com/murphb52/BabyTracker/blob/main/docs/privacy-policy.md

## App Privacy Answers

Use this as the starting point when filling App Store Connect privacy disclosures:

- Tracking: No
- Data linked to the user: child profile data, baby event history, optional child photo, diagnostics only if the exported log flow is considered collected data
- Data used for app functionality: child profiles, event history, caregiver sharing state, imported/exported backup content
- Diagnostics: only if App Store Connect classification requires exported in-app logs to be declared; otherwise keep diagnostics uncollected because logs remain on-device unless the user exports them
- Purchases, advertising, third-party tracking, and brokered data sharing: No

## Remaining App Store Connect Checklist

- [ ] choose final category
- [ ] enter age rating
- [ ] upload iPhone screenshots
- [ ] upload iPad screenshots if distributing on iPad
- [ ] paste the App Review notes from `docs/app-review-notes.md`
- [ ] confirm the privacy nutrition labels match `Baby Tracker/PrivacyInfo.xcprivacy` and current app behavior
- [ ] confirm the support and privacy URLs are acceptable as temporary GitHub-hosted endpoints
