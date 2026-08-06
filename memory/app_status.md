---
name: app_status
description: eggd_msipro-score build/publish state, design decisions, testing status
type: project
---

# eggd_msipro-score — status

## What it is
DNAnexus app that scores a single tumour-only CGP-panel BAM for microsatellite instability
(MSI) status. Runs `msisensor-pro pro -b <baseline> -c 20` against a pre-built panel-specific
MSS baseline (from companion app `eggd_msipro-baseline`, separate repo), which makes `pro`
perform a likelihood-ratio test at each panel locus rather than just extracting raw
repeat-length distributions. Classifies the resulting unstable-site percentage against a
configurable threshold (default 8.0%).

This is the **only stage of the pipeline that runs repeatedly in production** — once per new
tumour sample. Renamed/promoted from a prototype applet `cgp-msi-score`, validated on a
48-sample cohort; underlying command and 8.0% threshold logic unchanged from that validation.

## Panel-specific threshold
8.0% (not msisensor-pro's generic 20% default, tuned for tumour-normal WGS/WES). Calibrated
against a 26-specimen labelled set (21 confirmed MSS, 5 confirmed MSI-H) from the EF v1
cohort: highest confirmed MSS score 6.47%, lowest confirmed MSI-H score 9.09%, gap 2.62pp,
100% sensitivity (5/5) and 100% specificity (21/21). Samples scoring 7–9% are equivocal →
refer for IHC. Exposed as optional input `msi_threshold`, not hardcoded.

## Build/publish status
- v1.0.0 published (current, first release): `app-J9V2Bzj4pq4GX6xjP1XVB9y6`
- Built as **app** not applet: `dx build --app --bill-to org-emee_1`, `dx publish`.
- Commit tested/published: `d5c1862` (includes the ldconfig fix) — identical to published
  app, no subsequent changes.

## Dependency fix: libhts.so.3
Same root cause and fix as companion app `eggd_msipro-baseline` (see that repo's memory for
full diagnostic detail): originally used org's `htslib_suite_asset` v1.22 (Ubuntu 20.04),
failed on Ubuntu 24.04 workers with `libhts.so.3: cannot open shared object file`. Root
cause: no `ldconfig` call after asset overlay extracts the library into `/usr/local/lib`, so
it's invisible to the dynamic linker for the externally-supplied `msisensor-pro` binary.
Fixed by (1) retargeting to new `htslib_suite_asset` v1.24 (Ubuntu 24.04,
`record-J9QzZyj487v9Gj2QgP7vK47g`, kept in `001_Reference` per explicit user instruction) and
(2) adding an explicit `ldconfig` call at the start of `main()` — fix (2) is what actually
resolves the issue.

## Testing performed
- **Single-sample smoke test** (PASS): real live BAM, sample `24302S0067` (not part of
  confirmed cohort, used only to prove app mechanics). Result: 13,470 sites, 5.36% score,
  722 unstable sites, MSS call — consistent with the cohort's MSS score range (5.0–7.1%).
  No shared-library errors. Job: `job-J9V06K0491Gpq4pQFYp690fg`.
- **Repeatability** (PASS, n=10): published app v1.0.0 run 10× with identical input.
  `msi_tsv` output byte-identical (md5 `d07c13e352c4655e4dfbcc1955589949`) across all 10
  runs, no interruptions. Avg 7.95 min/run, avg $0.021/run, total $0.21. Job IDs and
  commands documented in Confluence (see `memory/confluence_and_dnanexus_ids.md`).
- **Deferred / not done** (flagged as gaps vs. org reference standard `eggd_cnv_chr_strip`,
  explicitly descoped by user + reviewer to keep this round to repeatability-only): no unit
  tests, no re-run of the labelled 26-specimen sensitivity/specificity comparison against
  this exact app build (only re-verified command/threshold logic is unchanged from the
  prototype's validation). The 5 confirmed MSI-H BAMs needed for that are archived (not
  unarchived) in `project-J88p7V0470jPZ2Vv1VqB3BFz`. May resurface in a future round.

## Design decisions
- Made threshold configurable (`msi_threshold`, default 8.0) rather than hardcoded.
- Replaced `bc` (used by the prototype for the floating-point threshold comparison) with
  `awk`, removing a runtime dependency that would otherwise need an `execDepends` entry.
- `msisensor_pro` supplied as plain `file` input, not `assetDepends`, since it's a
  custom-compiled binary not available via apt or an existing asset.

## Not yet through formal sign-off
Published ahead of the org's formal Jira/Confluence sign-off process because the Driver
(Joo Wook Ahn) will shortly be away with reduced capacity. Confluence page is still status
`Draft`.
