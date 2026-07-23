#!/bin/bash
# shellcheck disable=SC2154  # DNAnexus sets input-spec variables at runtime
# eggd_msipro-score
#
# Per-sample MSI scoring app — the only stage of the pipeline that runs
# repeatedly in production. Runs msisensor-pro pro with a pre-built
# panel-specific MSS baseline (from eggd_msipro-baseline) supplied via -b,
# which performs a likelihood-ratio test at each panel locus against the MSS
# background instead of just extracting raw distributions. The resulting
# unstable-site percentage is then classified against a panel-calibrated
# threshold (default 8.0% — NOT msisensor-pro's generic 20% default, which is
# tuned for tumour-normal WGS/WES, not a tumour-only targeted panel).

set -exo pipefail

main() {
    echo "=== eggd_msipro-score: ${sample_id} ==="

    dx download "${msisensor_pro}" -o msisensor-pro
    chmod +x msisensor-pro

    echo "[1/3] Downloading inputs..."
    dx download "${tumour_bam}"   -o tumour.bam
    dx download "${tumour_bai}"   -o tumour.bam.bai
    dx download "${msi_sites}"    -o msi_sites.txt
    dx download "${baseline_tar}" -o baseline.tar.gz
    tar --no-same-owner -xzf baseline.tar.gz

    BASELINE_FILE="baseline_out/cgp_msi_baseline"
    [[ -f "${BASELINE_FILE}" ]] \
        || { echo "ERROR: baseline file not found after extract"; ls -lR baseline_out/ 2>/dev/null || ls; exit 1; }

    THRESHOLD="${msi_threshold:-8.0}"

    echo "[2/3] Running msisensor-pro pro with baseline (threshold ${THRESHOLD}%)..."
    mkdir -p output/
    ./msisensor-pro pro \
        -d msi_sites.txt \
        -t tumour.bam \
        -o "output/${sample_id}" \
        -b "${BASELINE_FILE}" \
        -c 20

    SCORE_FILE="output/${sample_id}"
    [[ -s "${SCORE_FILE}" ]] || { echo "ERROR: score file missing"; ls output/; exit 1; }

    # Score file: header line + data line
    # Columns: Total_Number_of_Sites  Number_of_Somatic_Sites  %
    MSI_SCORE=$(awk 'NR==2{print $3}' "${SCORE_FILE}")
    TOTAL_SITES=$(awk 'NR==2{print $1}' "${SCORE_FILE}")
    UNSTABLE=$(awk 'NR==2{print $2}' "${SCORE_FILE}")

    MSI_STATUS=$(awk -v score="${MSI_SCORE}" -v thresh="${THRESHOLD}" \
        'BEGIN { print (score >= thresh) ? "MSI-H" : "MSS" }')

    printf 'sample_id\tmsi_score\ttotal_sites\tunstable_sites\tmsi_status\tthreshold\ttool_version\n' \
        > "${sample_id}.msi.tsv"
    printf '%s\t%s\t%s\t%s\t%s\t%s\tmsisensor-pro-v1.3.0\n' \
        "${sample_id}" "${MSI_SCORE}" "${TOTAL_SITES}" "${UNSTABLE}" "${MSI_STATUS}" "${THRESHOLD}" \
        >> "${sample_id}.msi.tsv"

    echo "  Sample:         ${sample_id}"
    echo "  Total sites:    ${TOTAL_SITES}"
    echo "  Unstable sites: ${UNSTABLE}"
    echo "  MSI score:      ${MSI_SCORE}%"
    echo "  Threshold:      ${THRESHOLD}%"
    echo "  Status:         ${MSI_STATUS}"
    [[ "${MSI_STATUS}" == "MSI-H" ]] && echo "  *** MSI-HIGH DETECTED ***"

    echo "[3/3] Uploading..."
    msi_tsv=$(dx upload "${sample_id}.msi.tsv" --wait --brief)
    dx-jobutil-add-output msi_tsv "${msi_tsv}" --class=file

    echo "=== eggd_msipro-score DONE: ${sample_id} ${MSI_STATUS} (${MSI_SCORE}%) ==="
}
