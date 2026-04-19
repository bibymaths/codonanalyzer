#!/usr/bin/env bash
set -euo pipefail

echo "==> Stopping and removing codonanalyzer containers and volumes..."
docker compose down -v
echo "==> Done."
