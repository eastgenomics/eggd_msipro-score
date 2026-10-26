<!-- dx-header -->
# eggd_msipro-score (DNAnexus Platform App)

## What does this app do?

Scores a single tumour-only CGP-panel BAM for microsatellite instability (MSI) status using `msisensor-pro pro` with a pre-built panel-specific MSS baseline supplied via `-d`. `pro` reads each locus's instability threshold from column 8 of the `-d` file: the baseline carries per-locus thresholds trained on MSS samples, so each locus is judged against the MSS background rather than a single generic cut-off — the output is a single unstable-site percentage, which is then classified against a configurable threshold.

`pro` runs with `-b` set to the instance's CPU count (`nproc`); it parallelises per-window locus scanning across those threads, so a larger instance type speeds up scoring.

The file in the tarball is not checked. A scan/sites file packaged as the baseline carries `-1` in the threshold column, which `pro` replaces with its generic `-i` cut-off (0.1) — i.e. scoring without a baseline, as v1.0.0 did.

> **v1.0.0 did not use the baseline.** It passed the scan file as `-d` and the baseline as `-b`, which `pro` reads as its thread count. Every v1.0.0 score was therefore computed against the generic 0.1 cut-off at every locus, regardless of which baseline was supplied. Scores from v1.0.0 and v1.1.0 are not comparable.

This is the only stage of the MSIsensor-pro CGP-panel pipeline that runs repeatedly in production — once per new tumour sample. The one-off setup/calibration stages (site scanning and baseline construction) are a separate app, [`eggd_msipro-baseline`](https://github.com/eastgenomics/eggd_msipro-baseline), whose `baseline_tar` output is a required input here. Its `msi_sites` output is not used by this app from v1.1.0.

## What are typical use cases for this app?

Routine per-sample MSI status calling for FFPE tumour-only CGP + backbone panel specimens, where no matched normal is available and the standard Bethesda PCR/IHC panel has not been run (or as a supporting/orthogonal call alongside it).

## What are the inputs?

| Input | Required | Type | Description |
| --- | --- | --- | --- |
| `tumour_bam` | Yes | file | Tumour-only BAM, chr-prefixed |
| `tumour_bai` | Yes | file | Index matching `tumour_bam` |
| `sample_id` | Yes | string | Sample identifier, used to name the output TSV |
| `baseline_tar` | Yes | file | `cgp_msi_baseline.tar.gz` output from `eggd_msipro-baseline` |
| `msisensor_pro` | Yes | file | Pre-compiled msisensor-pro v1.3.0 binary |
| `msi_threshold` | No | float | MSI-H unstable-site percentage cut-off (default `8.0`) |
| `min_coverage` | No | int | Minimum read coverage for a locus to be evaluated — msisensor-pro `-c` (default `20`) |

## What does this app output?

| Output | Type | Description |
| --- | --- | --- |
| `msi_tsv` | file | `<sample_id>.msi.tsv` — `sample_id`, `msi_score`, `total_sites`, `unstable_sites`, `msi_status`, `threshold`, `tool_version` |

## How to run this app from the command line?

```
dx run eggd_msipro-score \
  -itumour_bam=file-xxxx \
  -itumour_bai=file-yyyy \
  -isample_id="S0110" \
  -ibaseline_tar=file-wwww \
  -imsisensor_pro=file-vvvv \
  --instance-type mem1_ssd1_v2_x2 \
  --priority high
```

## Panel-specific threshold calibration

> **Needs re-deriving for v1.1.0.** The calibration below was performed on scores produced without the baseline (see above). With the baseline applied, scores are substantially lower — an MSS sample that scored 5.50% under v1.0.0 scores ~1.6% — so the 8.0% default is not valid for v1.1.0 output until the threshold is recalibrated against the labelled set.

The default 8.0% threshold is **not** msisensor-pro's generic 20% default (which is tuned for tumour-normal WGS/WES). It was calibrated for the CGP + backbone panel (~14,752 loci) against a 26-specimen labelled set (21 confirmed MSS, 5 confirmed MSI-H) from the EF v1 cohort:

- Highest confirmed MSS score: 6.47%
- Lowest confirmed MSI-H score: 9.09%
- Gap between classes: 2.62 percentage points
- Selected threshold (8.0%) achieves 100% sensitivity (5/5) and 100% specificity (21/21) on the labelled set
- Samples scoring 7-9% should be treated as equivocal and referred for IHC confirmation

A minimum evaluable-site QC gate (e.g. `total_sites` >= 1,000) is recommended downstream to suppress artefactual calls from low-coverage/QC-fail BAMs — this app does not apply that gate itself, since it operates on a single sample without cohort context.
