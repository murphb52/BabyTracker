# 113 — Stop sync getting stuck until the app is relaunched

GitHub issue: #285

## Problem

Every so often sync stops making progress and the only fix is to kill and
relaunch the app.

`CloudKitSyncEngine` runs refresh passes one at a time: each new pass waits
for the previous one to finish (added to stop two passes racing on change
tokens). A pass awaits CloudKit requests with no deadline. If one of those
requests never returns — which happens when the app is suspended mid-request
(the background flush in `appDidEnterBackground`, a silent-push wake, a
background refresh) or the network drops — that pass never finishes, and every
later pass (foreground, pull-to-refresh, after a local write) queues behind it
forever. The sync indicator stays on "Syncing" and nothing reaches CloudKit.
Relaunching clears the in-memory queue, which is why killing the app helps.

The background-refresh deadline in `AppModel` does not help here: it
deliberately returns to iOS while leaving the stalled pass running, so the
queue stays blocked.

A second, related gap: an expired change token for the **shared** database is
not handled (the per-zone path already falls back to a full fetch). Once that
token expires, every refresh fails at the same point.

## Approach

1. **Deadline per CloudKit request.** Syncs normally take 2–10 seconds, so
   no single CloudKit request should take longer than `requestTimeout`
   (default 10 s, settable for tests). The engine wraps its client in
   `RequestTrackingCloudKitClient`, which records each request's start and
   finish in a `CloudKitRequestTracker`. Each pass runs in its own task with a
   watchdog that checks every second; once a request has been in flight
   longer than the limit, it cancels the pass. The limit is per request, not
   per pass, so a large import made of many quick requests can still finish.
   CloudKit's async APIs honour task cancellation, so the stalled request
   throws and the pass ends with a `.failed` summary ("Sync took too long…").
   The queue still waits for the cancelled pass to finish, so passes never
   overlap. Add `Task.checkCancellation()` at the top of the per-child loops
   and the CloudKit pagination loops so a cancelled pass stops promptly.
2. **Recover from an expired shared-database token.** When
   `databaseChanges` throws `.changeTokenExpired`, restart the shared database
   fetch from scratch, matching the existing zone-level behaviour.

3. **Keep upload progress when a pass is cut short.** Pushes go out in
   batches of 400. Record each batch's results as soon as it saves, instead
   of after every batch, so an interrupted import doesn't re-upload the
   batches that already landed.

## Tests

- A refresh whose CloudKit call stalls returns a timed-out failure, and the
  next refresh completes normally.
- An expired shared-database token triggers a fetch with no token and the
  refresh succeeds.
- A push whose second batch stalls keeps the first 400 records marked as
  synced.

- [x] Complete
