#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

echo "============================================="
echo " codonanalyzer test suite"
echo "============================================="

echo ""
echo "--> Running unit tests (prove)..."
prove -v tests/unit/*.t
UNIT_RC=$?

echo ""
echo "--> Running Nextflow integration test..."
if command -v nextflow &>/dev/null; then
    nextflow run main.nf -profile test --outdir results_test
    NF_RC=$?
    rm -rf results_test work .nextflow .nextflow.log* 2>/dev/null || true
else
    echo "WARNING: nextflow not found in PATH — skipping integration test."
    NF_RC=0
fi

echo ""
if [ "${UNIT_RC}" -eq 0 ] && [ "${NF_RC}" -eq 0 ]; then
    echo "============================================="
    echo " All tests PASSED."
    echo "============================================="
    exit 0
else
    echo "============================================="
    echo " Some tests FAILED (unit=${UNIT_RC}, nf=${NF_RC})."
    echo "============================================="
    exit 1
fi
