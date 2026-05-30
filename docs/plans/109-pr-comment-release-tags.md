# 109 PR Comment Release Tags

## Goal

Add a GitHub Actions workflow that lets maintainers create release trigger tags from a pull request comment.

## Approach

1. Create a new `issue_comment` workflow that only runs for pull request comments beginning with `tag ` on pull requests.
2. Resolve the pull request head SHA through the GitHub API so tag and release work starts from the latest commit on the PR branch, not the base branch or a merge ref.
3. Restrict tag and release creation to trusted commenters and same-repository pull requests before granting the workflow permission to write tags or branches.
4. Support `tag TestFlight` by finding existing `TestFlight-<number>` tags, creating the next numbered tag, and pushing that lightweight tag at the PR head SHA.
5. Support `tag Release major`, `tag Release minor`, and `tag Release patch` by bumping the marketing version by the requested component, incrementing build numbers, committing those version-file changes to a release branch, pushing a `Release-<version>` tag, and opening a pull request into `main`.
6. Treat these repository values as release-version inputs that must move together:
   - `MARKETING_VERSION` in `Config/App.xcconfig`, `Config/LiveActivitiesExtension.xcconfig`, `Config/Tests.xcconfig`, and `Config/UITests.xcconfig`.
   - `CURRENT_PROJECT_VERSION` in the same xcconfig files.
   - `CURRENT_PROJECT_VERSION` in `Baby Tracker.xcodeproj/project.pbxproj`, which still has app-target build settings that can override inherited configuration values.
7. Comment back on the PR with either created tag details, release bump PR details, or a clear rejection/failure message.
8. Validate the workflow YAML and review the diff for unrelated changes.

- [x] Complete
