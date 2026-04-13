---
name: github-pr-review-operation
description: Use this skill when the user needs to interact with a GitHub Pull Request — reviewing code, reading diffs, posting review comments, or replying to existing comments. Activate even when the user provides just a PR URL and asks to "check it" or "leave feedback" without explicitly mentioning "review."
---

# GitHub PR Review Operation

PR review operations using GitHub CLI (`gh`).

## Prerequisites

- `gh` installed
- Authenticated via `gh auth login`

## Resolving OWNER/REPO/NUMBER

**Never guess `OWNER`, `REPO`, or `NUMBER` from directory names, paths, or context.**
Incorrect guesses cause 404 errors and waste API calls.

Pick the approach that matches the input, then use the resulting `OWNER`, `REPO`, and
`NUMBER` in every Operation command that follows.

| Input | How to resolve |
|---|---|
| PR URL given (`https://github.com/OWNER/REPO/pull/NUMBER`) | Parse `OWNER`, `REPO`, `NUMBER` directly from the URL. |
| PR number given | Run `gh pr view <NUMBER> --json url --jq .url` and parse the returned URL. |
| No identifier (e.g., "this PR" on a branch) | Run `gh pr view --json url --jq .url` and parse the returned URL. |

For the `gh pr view` cases, the command resolves the number or branch against the current
working directory's git repository, so `OWNER/REPO` come from the real repo context
rather than a guess.

If `gh pr view` fails (not in a git repo, branch has no PR, invalid number), ask the user
for the full PR URL rather than guessing.

## Operations

### 1. Get PR Info

```bash
gh pr view NUMBER --repo OWNER/REPO --json title,body,author,state,baseRefName,headRefName,url
```

### 2. Get Diff (with line numbers)

```bash
gh pr diff NUMBER --repo OWNER/REPO | awk '
/^@@/ {
  match($0, /-([0-9]+)/, old)
  match($0, /\+([0-9]+)/, new)
  old_line = old[1]
  new_line = new[1]
  print $0
  next
}
/^-/ { printf "L%-4d     | %s\n", old_line++, $0; next }
/^\+/ { printf "     R%-4d| %s\n", new_line++, $0; next }
/^ / { printf "L%-4d R%-4d| %s\n", old_line++, new_line++, $0; next }
{ print }
'
```

Example output:
```
@@ -46,15 +46,25 @@ jobs:
L46   R46  |            prompt: |
L49       | -            (deleted line)
     R49  | +            (added line)
L50   R50  |              # Review guidelines
```

- `L<number>`: LEFT (base) side line number - use with `side=LEFT` for inline comments
- `R<number>`: RIGHT (head) side line number - use with `side=RIGHT` for inline comments

### 3. Get Comments

Issue Comments (comments on the entire PR):
```bash
gh api repos/OWNER/REPO/issues/NUMBER/comments --jq '.[] | {id, user: .user.login, created_at, body}'
```

Review Comments (comments on specific code lines):
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments --jq '.[] | {id, user: .user.login, path, line, created_at, body, in_reply_to_id}'
```

### 4. Comment on PR

```bash
gh pr comment NUMBER --repo OWNER/REPO --body "Comment body"
```

### 5. Inline Comment (on specific code lines)

First, get the head commit SHA:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER --jq '.head.sha'
```

Single line comment:
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments \
  --method POST \
  -f body="Comment body" \
  -f commit_id="COMMIT_SHA" \
  -f path="src/example.py" \
  -F line=15 \
  -f side=RIGHT
```

Multi-line comment (lines 10-15):
```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments \
  --method POST \
  -f body="Comment body" \
  -f commit_id="COMMIT_SHA" \
  -f path="src/example.py" \
  -F line=15 \
  -f side=RIGHT \
  -F start_line=10 \
  -f start_side=RIGHT
```

**Notes:**
- `-F` (uppercase): Use for numeric parameters (`line`, `start_line`). Using `-f` sends them as strings and causes errors
- `side`: `RIGHT` (added lines) or `LEFT` (deleted lines)

### 6. Reply to a Comment

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments/COMMENT_ID/replies \
  --method POST \
  -f body="Reply body"
```

Use the `id` obtained from comment retrieval as `COMMENT_ID`.
