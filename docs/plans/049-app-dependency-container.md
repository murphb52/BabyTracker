# 049 App dependency container

## Goal
Make app composition easier to maintain by introducing a small dependency container at the app composition root. This should make dependency registration/resolution clearer and make test/preview overrides easier.

## Plan
1. Introduce a lightweight dependency container in `AppContainer` that supports:
   - registering factories by dependency type
   - registering prebuilt instances for overrides
   - resolving dependencies lazily
2. Move `AppContainer` composition code to dependency registrations so wiring is declared in one place.
3. Keep seeding behavior intact while switching seeding inputs to resolved dependencies.
4. Use the container in `.preview` to override live dependencies with no-op / unavailable test-friendly implementations.
5. Build and run targeted tests to validate the refactor.

## Notes
- This stays within the app composition root only.
- Feature/domain code still receives dependencies by initializer injection.

- [x] Complete
