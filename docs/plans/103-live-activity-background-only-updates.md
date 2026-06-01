# 103 Live activity background-only updates

> **⚠️ Superseded — see "Correction" below.**
> The background-only rule described here shipped in PR #241 but made Live
> Activities impossible to start. It was reversed in PR #269. Keep this doc as
> the record of why the original approach didn't work.

## Correction (PR #269)

The goal below restricted **all** live activity synchronization — including the
initial `Activity.request` — to background triggers. That cannot work:

**ActivityKit only permits *starting* a Live Activity while the app is in the
foreground.** Routing the first sync through `appDidEnterBackground` /
background remote notifications meant `Activity.request` was always called from
the background, threw every time, and the error was silently swallowed. The
activity therefore never started, and nothing appeared in the logs.

### Corrected design

1. Reconcile the live activity on every **successful foreground `refresh`**
   (launch, logging an event, switching child, toggling the feature on), so the
   activity is started while the app is actually allowed to start it.
2. Keep the background triggers (`appDidEnterBackground`, background remote
   notification) as **update** points for an already-running activity.
3. Preserve the original frugality intent through `UpdateFeedLiveActivityUseCase`
   deduplication: we only write when the snapshot actually changed (or no
   activity is running), so foreground refreshes with unchanged data are no-ops.
   Apple's tight update budget applies to *push* updates, not the cheap local
   `activity.update()` calls used here.
4. Surface the previously-swallowed failure path with logging under the
   `LiveActivity` category, plus an explicit
   `ActivityAuthorizationInfo.areActivitiesEnabled` check.

---

## Original goal (historical — no longer the behavior)

Restrict feed live activity synchronization so the app only pushes updates when:
1. the app transitions to the background, or
2. a remote/background notification is handled while the app is already in the background.

## Original approach (historical)

1. Move live activity synchronization control into explicit lifecycle-triggered paths instead of running on every `AppModel.refresh`.
2. Add an `AppModel` API for background transition updates, and call it from the root view when `scenePhase` becomes `.background`.
3. Update remote notification handling to pass whether the app is currently in background, and only synchronize the live activity in that case.
4. Add/update tests to verify background-triggered synchronization and to prevent foreground remote-notification synchronization.
5. Run focused test coverage for `AppModel` and related live activity behavior.

- [x] Complete (later superseded by PR #269)
</content>
</invoke>
