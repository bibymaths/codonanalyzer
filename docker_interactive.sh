#!/usr/bin/env bash
set -euo pipefail

echo "==> Starting interactive development shell in codonanalyzer container..."
docker compose -f docker-compose.dev.yml run --rm pipeline /bin/bash
