#!/usr/bin/env bash
# validate_predictive.sh: Validate predictive InferenceServices are READY
set -euo pipefail

NAMESPACE="ml-predictive"
EXPECTED_ISVCS=("resnet50" "sentence-bert")
FAILURES=0

echo "=== Validating Predictive InferenceServices ==="

if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "  [FAIL] Namespace $NAMESPACE does not exist"
  exit 1
fi

for isvc in "${EXPECTED_ISVCS[@]}"; do
  echo "--- $isvc ---"

  if ! kubectl get isvc "$isvc" -n "$NAMESPACE" &>/dev/null; then
    echo "  [FAIL] InferenceService $isvc not found"
    FAILURES=$((FAILURES + 1))
    continue
  fi

  READY=$(kubectl get isvc "$isvc" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")
  if [[ "$READY" == "True" ]]; then
    echo "  [PASS] $isvc is READY"
  else
    echo "  [WARN] $isvc is not READY (status: ${READY:-unknown})"
    FAILURES=$((FAILURES + 1))
  fi
done

if [[ $FAILURES -gt 0 ]]; then
  echo "[RESULT] $FAILURES validation(s) failed"
  exit 1
else
  echo "[RESULT] All predictive InferenceServices validated ✅"
fi
