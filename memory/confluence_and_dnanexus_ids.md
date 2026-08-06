---
name: confluence_and_dnanexus_ids
description: Confluence page IDs, DNAnexus app/asset/project IDs, and GitHub PR for eggd_msipro-score
type: reference
---

# Confluence & DNAnexus reference IDs

## Confluence (cuhbioinformatics.atlassian.net, space DV)
- `eggd_msipro-score v1.0.0` dev-doc: `4757192713` (current version 4; includes
  Testing Summary table + repeatability test H2 section)
- `eggd_msipro` parent index page: `4756537399`
- `htslib_suite_asset v1.24` (Ubuntu 24.04) page: `4756537462`
- Sibling app `eggd_msipro-baseline v1.0.1` dev-doc: `4757225481`
- Org reference standard used for testing-rigor comparison, APPROVED:
  `eggd_cnv_chr_strip v1.0.0` → `4739236128`

## DNAnexus
- Published app: v1.0.0 (current) `app-J9V2Bzj4pq4GX6xjP1XVB9y6`
- htslib asset: `record-J9QzZyj487v9Gj2QgP7vK47g`, location
  `project-Fkb6Gkj433GVVvj73J7x8KbV:/app_assets/htslib/htslib_v1.24.0/` (`001_Reference`)
- Validation project: `004_260723_msi_sensor_pro_validation` =
  `project-J9Qy1Bj491GkVyf0g5gVy882`
- Smoke test job: `job-J9V06K0491Gpq4pQFYp690fg` (sample `24302S0067`)
- Original cohort resource file IDs (in `project-J8F1Yq84gPFqgBp4XZ395fB3`):
  panel loci `file-J8J1KZ84YQBy6PK9GKXZpK4g`, baseline `file-J8J1p304y058QKQ70xqGj1yF`,
  msisensor-pro binary `file-J8J0xg04gPFjVPXJGJ9GB7GQ`
- Repeatability test jobs (10×, run1–run10):
  `job-J9V3VP8491GfjKxZbJqPvPj1`, `job-J9V3VPj491Gz4g21YJvjxYGK`,
  `job-J9V3VQ8491Gk889yQ0ybKVqv`, `job-J9V3VQj491Gg4FGy59Bj8kzJ`,
  `job-J9V3VV0491Gp0126F7PGfzBV`, `job-J9V3VVQ491Gz4g21YJvjxYGX`,
  `job-J9V3VX0491GbpbyV691xQpF8`, `job-J9V3VXQ491GQZPkJPvfqKgfv`,
  `job-J9V3VXj491GqBBv320k5J6QQ`, `job-J9V3VY8491GpgP2gKxb5Zk0X`
  (no interruptions, all identical)

## GitHub
- Repo: `eastgenomics/eggd_msipro-score`
- Open PR: https://github.com/eastgenomics/eggd_msipro-score/pull/2 (deliberately left
  open, not merged — GitHub permanently locks merged PRs, so `main` was reverted to empty
  and PR #2 reopened from `bootstrap-codebase`)
- Tag `pre-pr-bootstrap` preserves original pre-bootstrap commit history
- Commit: `d5c1862` (ldconfig/asset fix) — identical to the published app
