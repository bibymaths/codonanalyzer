#!/usr/bin/env bash
set -euo pipefail

echo "==> Building and starting codonanalyzer pipeline container..."
docker compose up -d --build

echo "==> Container logs:"
docker compose logs --tail=50
