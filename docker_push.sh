#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/bibymaths/codonanalyzer"
TAG_LATEST="${IMAGE}:latest"
TAG_VERSION="${IMAGE}:$(git describe --tags 2>/dev/null || echo 'dev')"

echo "==> Tagging image as ${TAG_LATEST} and ${TAG_VERSION}..."
docker tag codonanalyzer-pipeline "${TAG_LATEST}"
docker tag codonanalyzer-pipeline "${TAG_VERSION}"

echo "==> Pushing ${TAG_LATEST}..."
docker push "${TAG_LATEST}"

echo "==> Pushing ${TAG_VERSION}..."
docker push "${TAG_VERSION}"

echo "==> Done."
