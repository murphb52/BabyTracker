# 049 Dependency Container Improvements

## Goal
Make app dependency wiring easier to maintain and easier to customize for tests and SwiftUI previews.

## Approach
1. Add a small dependency container type that supports explicit register and resolve operations.
2. Refactor `AppContainer` to build dependencies once and resolve them when constructing `AppModel` and share acceptance handling.
3. Keep default launch behavior unchanged while allowing preview-specific overrides without duplicating the full dependency wiring block.
4. Run focused tests to verify the app and feature package still build and pass relevant tests.

- [x] Complete
