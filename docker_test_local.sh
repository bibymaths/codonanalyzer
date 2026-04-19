#!/usr/bin/env bash
set -euo pipefail

IMAGE="codonanalyzer-test"

echo "==> Building Docker image for local testing..."
docker build -t "${IMAGE}" .

echo "==> Running Nextflow test profile inside container..."
EXIT_CODE=0
docker run --rm \
    -v "$(pwd)/data:/pipeline/data" \
    -v "$(pwd)/results:/pipeline/results" \
    "${IMAGE}" \
    -profile test,docker || EXIT_CODE=$?

if [ "${EXIT_CODE}" -eq 0 ]; then
    echo "==> Test PASSED (exit code 0)."
else
    echo "==> Test FAILED (exit code ${EXIT_CODE})."
    exit "${EXIT_CODE}"
fi
