# 109 PR Comment Release Tags

## Goal

Add a GitHub Actions workflow that lets maintainers create release trigger tags from a pull request comment.

## Approach

1. Create a new `issue_comment` workflow that only runs for pull request comments matching `tag Release` or `tag TestFlight`.
2. Resolve the pull request head SHA through the GitHub API so the tag points at the latest commit on the PR branch, not the base branch or a merge ref.
3. Restrict tag creation to trusted commenters and same-repository pull requests before granting the workflow permission to write tags.
4. Create a unique lightweight tag using the requested tag family as a prefix, then push it with the workflow token.
5. Comment back on the PR with either the created tag details or a clear rejection/failure message.
6. Validate the workflow YAML and review the diff for unrelated changes.

- [x] Complete
