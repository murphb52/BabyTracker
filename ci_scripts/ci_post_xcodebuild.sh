#!/bin/zsh

set -euo pipefail

if [[ ! -d "${CI_APP_STORE_SIGNED_APP_PATH:-}" ]]; then
  echo "Skipping TestFlight note generation because this build is not producing a signed app."
  exit 0
fi

SCRIPT_DIR="${0:A:h}"
REPO_ROOT="${SCRIPT_DIR:h}"
TESTFLIGHT_DIR="${REPO_ROOT}/TestFlight"
WHAT_TO_TEST_PATH="${TESTFLIGHT_DIR}/WhatToTest.en-US.txt"

mkdir -p "${TESTFLIGHT_DIR}"

branch_name="${CI_BRANCH:-$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")}"

recent_commits="$(
  git -C "${REPO_ROOT}" log -3 --pretty=format:'- %h %s (%an)' 2>/dev/null || true
)"

extract_repo_slug() {
  local remote_url
  remote_url="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"

  if [[ "${remote_url}" =~ github\.com[:/]([^/]+/[^/.]+)(\.git)?$ ]]; then
    echo "${match[1]}"
  fi
}

pull_request_section() {
  local pr_number repo_slug api_url response

  pr_number="${CI_PULL_REQUEST_NUMBER:-}"
  if [[ -z "${pr_number}" ]]; then
    return 0
  fi

  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    cat <<EOF
Pull Request
- #${pr_number}
- GitHub token not configured, so PR details were not fetched.
EOF
    return 0
  fi

  repo_slug="$(extract_repo_slug)"
  if [[ -z "${repo_slug}" ]]; then
    cat <<EOF
Pull Request
- #${pr_number}
- Could not determine the GitHub repository from the origin remote.
EOF
    return 0
  fi

  api_url="https://api.github.com/repos/${repo_slug}/pulls/${pr_number}"
  response="$(
    curl --silent --show-error --fail \
      --header "Accept: application/vnd.github+json" \
      --header "Authorization: Bearer ${GITHUB_TOKEN}" \
      --header "X-GitHub-Api-Version: 2022-11-28" \
      "${api_url}" 2>/dev/null || true
  )"

  if [[ -z "${response}" ]]; then
    cat <<EOF
Pull Request
- #${pr_number}
- GitHub API request failed, so PR details were not fetched.
EOF
    return 0
  fi

  PR_NUMBER="${pr_number}" PR_PAYLOAD="${response}" python3 <<'PY'
import json
import os
import re

payload = json.loads(os.environ["PR_PAYLOAD"])
number = os.environ["PR_NUMBER"]
title = (payload.get("title") or "").strip()
body = payload.get("body") or ""

lines = []
for raw_line in body.splitlines():
    line = raw_line.strip()
    if not line:
        continue
    if line in {"---", "***", "___"}:
        continue
    line = re.sub(r"^[-*+]\s*", "", line)
    line = re.sub(r"^\d+\.\s*", "", line)
    line = re.sub(r"`([^`]*)`", r"\1", line)
    line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line)
    line = re.sub(r"^#+\s*", "", line)
    line = re.sub(r"\s+", " ", line).strip()
    if line:
        lines.append(line)
    if len(lines) == 4:
        break

print("Pull Request")
print(f"- #{number}: {title or 'Untitled pull request'}")
if lines:
    print("- Summary:")
    for line in lines:
        print(f"  {line}")
else:
    print("- No PR summary text was present.")
PY
}

pr_details="$(pull_request_section)"

WHAT_TO_TEST_PATH="${WHAT_TO_TEST_PATH}" \
BRANCH_NAME="${branch_name}" \
RECENT_COMMITS="${recent_commits}" \
PR_DETAILS="${pr_details}" \
python3 <<'PY'
import os

max_length = 3800

branch_name = os.environ["BRANCH_NAME"].strip() or "unknown"
recent_commits = os.environ["RECENT_COMMITS"].strip() or "- No commit history available."
pr_details = os.environ["PR_DETAILS"].strip()
output_path = os.environ["WHAT_TO_TEST_PATH"]

sections = [
    "Focus areas for this build:",
    "",
    f"Branch\n- {branch_name}",
    "",
    "Recent Commits",
    recent_commits,
]

if pr_details:
    sections.extend(["", pr_details])

content = "\n".join(sections).strip()

if len(content) > max_length:
    content = content[: max_length - 14].rstrip() + "\n\n[Truncated]"

with open(output_path, "w", encoding="utf-8") as handle:
    handle.write(content + "\n")
PY

echo "Generated TestFlight notes at ${WHAT_TO_TEST_PATH}"
