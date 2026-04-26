# 103 Live activity background-only updates

## Goal

Restrict feed live activity synchronization so the app only pushes updates when:
1. the app transitions to the background, or
2. a remote/background notification is handled while the app is already in the background.

## Approach

1. Move live activity synchronization control into explicit lifecycle-triggered paths instead of running on every `AppModel.refresh`.
2. Add an `AppModel` API for background transition updates, and call it from the root view when `scenePhase` becomes `.background`.
3. Update remote notification handling to pass whether the app is currently in background, and only synchronize the live activity in that case.
4. Add/update tests to verify background-triggered synchronization and to prevent foreground remote-notification synchronization.
5. Run focused test coverage for `AppModel` and related live activity behavior.

- [x] Complete
