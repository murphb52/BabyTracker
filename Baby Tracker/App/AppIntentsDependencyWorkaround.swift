import AppIntents

// Xcode 26 runs App Intents metadata extraction for the app target during Release builds.
// Keeping the framework dependency explicit avoids a spurious warning when the app does not
// define any App Intents yet.
