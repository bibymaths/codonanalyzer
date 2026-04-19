#!/usr/bin/env bash
set -euo pipefail

SOURCE_IMAGE="codonanalyzer-pipeline"
IMAGE="ghcr.io/bibymaths/codonanalyzer"
TAG_LATEST="${IMAGE}:latest"
TAG_VERSION="${IMAGE}:$(git describe --tags 2>/dev/null || echo 'dev')"

echo "==> Building local image ${SOURCE_IMAGE}..."
docker build -t "${SOURCE_IMAGE}" .

echo "==> Tagging image as ${TAG_LATEST} and ${TAG_VERSION}..."
docker tag "${SOURCE_IMAGE}" "${TAG_LATEST}"
docker tag "${SOURCE_IMAGE}" "${TAG_VERSION}"

echo "==> Pushing ${TAG_LATEST}..."
docker push "${TAG_LATEST}"

echo "==> Pushing ${TAG_VERSION}..."
docker push "${TAG_VERSION}"

echo "==> Done."
