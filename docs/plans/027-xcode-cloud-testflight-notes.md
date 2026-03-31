# Xcode Cloud TestFlight Notes

## Goal

Add an Xcode Cloud post-build script that generates TestFlight "What to Test" notes automatically.

## Plan

1. Add a `ci_post_xcodebuild.sh` script in a repo-level `ci_scripts` folder.
2. Generate `TestFlight/WhatToTest.en-US.txt` only for signed archive builds that Xcode Cloud is preparing for distribution.
3. Include the current branch name and the last three commits from git history.
4. Include pull request context when Xcode Cloud exposes a pull request number and a GitHub token is available.
5. Document the required Xcode Cloud setup so the script is easy to wire into the workflow.

- [x] Complete
