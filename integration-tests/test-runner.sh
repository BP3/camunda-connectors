#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/test-compose.yaml"

: "${CAMUNDA_VERSION:?CAMUNDA_VERSION must be set (see gradle.properties: versionCamunda)}"
: "${CONNECTOR_IMAGE:?CONNECTOR_IMAGE must be set to the image under test}"

cleanup() {
  echo "--- Test stack logs ---"
  docker compose -f "$COMPOSE_FILE" logs || true
  echo "--- Tearing down test stack ---"
  docker compose -f "$COMPOSE_FILE" down -v --remove-orphans || true
}
trap cleanup EXIT

echo "--- Starting test stack (camunda:${CAMUNDA_VERSION}, connector:${CONNECTOR_IMAGE}) ---"
docker compose -f "$COMPOSE_FILE" up -d --wait

# shellcheck source=functions.sh
source "${SCRIPT_DIR}/functions.sh"
wait_for_camunda
wait_for_connector

failures=0
for test_script in "${SCRIPT_DIR}"/tests/*.sh; do
  echo "=== Running $(basename "$test_script") ==="
  if ! bash "$test_script"; then
    echo "FAILED: $(basename "$test_script")" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed" >&2
  exit 1
fi

echo "All integration tests passed"
