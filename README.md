<!-- dx-header -->
# eggd_msipro-score (DNAnexus Platform App)

## What does this app do?

Scores a single tumour-only CGP-panel BAM for microsatellite instability (MSI) status using `msisensor-pro pro` with a pre-built panel-specific MSS baseline supplied via `-b`. Supplying the baseline makes `pro` perform a likelihood-ratio test at each panel locus against the MSS background, rather than just extracting raw repeat-length distributions — the output is a single unstable-site percentage, which is then classified against a configurable threshold.

This is the only stage of the MSIsensor-pro CGP-panel pipeline that runs repeatedly in production — once per new tumour sample. The one-off setup/calibration stages (site scanning and baseline construction) are a separate app, [`eggd_msipro-baseline`](https://github.com/eastgenomics/eggd_msipro-baseline), whose two outputs (`msi_sites`, `baseline_tar`) are required inputs here.

## What are typical use cases for this app?

Routine per-sample MSI status calling for FFPE tumour-only CGP + backbone panel specimens, where no matched normal is available and the standard Bethesda PCR/IHC panel has not been run (or as a supporting/orthogonal call alongside it).

## What are the inputs?

| Input | Required | Type | Description |
| --- | --- | --- | --- |
| `tumour_bam` | Yes | file | Tumour-only BAM, chr-prefixed |
| `tumour_bai` | Yes | file | Index matching `tumour_bam` |
| `sample_id` | Yes | string | Sample identifier, used to name the output TSV |
| `msi_sites` | Yes | file | `cgp_msi_sites.txt` output from `eggd_msipro-baseline` |
| `baseline_tar` | Yes | file | `cgp_msi_baseline.tar.gz` output from `eggd_msipro-baseline` |
| `msisensor_pro` | Yes | file | Pre-compiled msisensor-pro v1.3.0 binary |
| `msi_threshold` | No | float | MSI-H unstable-site percentage cut-off (default `8.0`) |

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
  -imsi_sites=file-zzzz \
  -ibaseline_tar=file-wwww \
  -imsisensor_pro=file-vvvv \
  --instance-type mem1_ssd1_v2_x2
```

## Panel-specific threshold calibration

The default 8.0% threshold is **not** msisensor-pro's generic 20% default (which is tuned for tumour-normal WGS/WES). It was calibrated for the CGP + backbone panel (~14,752 loci) against a 26-specimen labelled set (21 confirmed MSS, 5 confirmed MSI-H) from the EF v1 cohort:

- Highest confirmed MSS score: 6.47%
- Lowest confirmed MSI-H score: 9.09%
- Gap between classes: 2.62 percentage points
- Selected threshold (8.0%) achieves 100% sensitivity (5/5) and 100% specificity (21/21) on the labelled set
- Samples scoring 7-9% should be treated as equivocal and referred for IHC confirmation

A minimum evaluable-site QC gate (e.g. `total_sites` >= 1,000) is recommended downstream to suppress artefactual calls from low-coverage/QC-fail BAMs — this app does not apply that gate itself, since it operates on a single sample without cohort context.
