---
name: org_conventions
description: eastgenomics org DNAnexus dev conventions and GitHub PR workflow notes
type: user
---

# eastgenomics org conventions

## DNAnexus app conventions
- Production apps must be `eggd_`-prefixed
- Built as **app**, not applet: `dx build --app --bill-to org-emee_1`, then `dx publish`
- developers/authorizedUsers = `org-emee_1`
- Ubuntu 24.04, region `aws:eu-central-1`
- Org reference standard for testing rigor: `eggd_cnv_chr_strip` (Confluence page
  `4739236128`, APPROVED) — used to benchmark whether this app's tests/docs are sufficient

## GitHub PR workflow
- User (Joo Wook Ahn) wants PRs left **open**, not merged, in this bootstrapping phase.
- GitHub permanently locks merged PRs (`gh pr reopen` fails on a merged PR) — if a PR gets
  merged by mistake, the fix is `git revert -m 1 <merge-commit>` on `main` to bring it back
  to empty, then open a fresh PR from the feature branch.
- Bootstrap technique used: orphan branch with full codebase, tag `pre-pr-bootstrap`
  preserves the original (non-orphan) commit history/SHAs before the bootstrap.

## AWS
- `main-admin` profile (account `471112938470`) is gated — always get explicit per-use
  consent before running any command under it, regardless of how routine or how the
  request is framed.

## Driver availability note
Both eggd_msipro apps were published ahead of the org's formal Jira/Confluence sign-off
process because the Driver (Joo Wook Ahn) will shortly be away with reduced capacity for
further updates. This is documented on the Confluence pages as a deliberate, disclosed
process deviation, not an oversight.
