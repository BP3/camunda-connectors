#!/usr/bin/env bash

ZEEBE_REST="${ZEEBE_REST:-http://localhost:8088}"
CONNECTOR_ACTUATOR="${CONNECTOR_ACTUATOR:-http://localhost:8089}"

wait_for_readiness() {
  local url="$1" description="$2"
  local attempts=40
  local delay=5
  for ((i = 1; i <= attempts; i++)); do
    if curl -sf "${url}" >/dev/null 2>&1; then
      echo "${description} is ready (${url})"
      return 0
    fi
    echo "Waiting for ${description} (${i}/${attempts})..."
    sleep "${delay}"
  done
  echo "${description} did not become ready at ${url}" >&2
  return 1
}

wait_for_camunda() {
  wait_for_readiness "http://localhost:9600/actuator/health/readiness" "Camunda"
}

wait_for_connector() {
  wait_for_readiness "${CONNECTOR_ACTUATOR}/actuator/health/readiness" "Connector bundle"
}

assert_equals() {
  local actual="$1" expected="$2" description="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAILED: ${description}: expected '${expected}', got '${actual}'" >&2
    return 1
  fi
  echo "OK: ${description} (${actual})"
}

assert_not_empty() {
  local value="$1" description="$2"
  if [[ -z "$value" || "$value" == "null" ]]; then
    echo "FAILED: ${description}: value was empty/null" >&2
    return 1
  fi
  echo "OK: ${description} (${value})"
}
