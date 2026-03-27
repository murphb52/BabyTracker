# 024 - Remote notification triggers

## Goal

Implement CloudKit remote notification trigger support so devices reconcile faster without waiting for foreground sync.

## Plan

1. Extend the CloudKit client contract to support fetching and saving database subscriptions.
2. Add concrete subscription support in the live client and safe fallbacks in the unavailable client.
3. Update the sync engine to ensure subscriptions exist and add a dedicated remote-notification refresh path.
4. Wire app lifecycle callbacks for APNs registration and silent CloudKit push handling in the app delegate.
5. Add a feature-layer entry point to refresh app state after remote-triggered sync.
6. Add/extend tests for subscription creation and remote refresh behavior.

- [x] Complete
