#!/usr/bin/env bash
# setup_namespaces.sh: Idempotent namespace creation for ML Reference platform
set -euo pipefail

NAMESPACES=(
  ml-predictive
  ml-generative
  ml-graphs
  ml-monitoring
)

LABEL="app.kubernetes.io/part-of=kserve-gitops-blueprint"

echo "=== Creating ML Reference namespaces ==="

for ns in "${NAMESPACES[@]}"; do
  if kubectl get namespace "$ns" &>/dev/null; then
    echo "  [exists] $ns"
  else
    kubectl create namespace "$ns"
    echo "  [created] $ns"
  fi
  # Ensure label is set (idempotent)
  kubectl label namespace "$ns" "$LABEL" --overwrite
done

echo "=== Namespace setup complete ==="
kubectl get namespaces -l "$LABEL"
