#!/usr/bin/env bash
# setup_secrets.sh: Idempotent secret creation for ML Reference platform
#
# Creates:
#   1. HuggingFace token secret (for gated model downloads)
#   2. Container registry pull secret (optional, for private images)
#
# Usage:
#   export HF_TOKEN="hf_xxxxx"
#   bash scripts/setup/setup_secrets.sh
set -euo pipefail

HF_SECRET_NAME="hf-token-secret"
HF_SECRET_SOURCE_NS="${HF_SECRET_SOURCE_NS:-}"
HF_SECRET_SOURCE_NAME="${HF_SECRET_SOURCE_NAME:-hf-token-secret}"

GENERATIVE_NAMESPACES=(
  ml-generative
)

ALL_NAMESPACES=(
  ml-predictive
  ml-generative
  ml-graphs
  ml-monitoring
)

echo "=== Creating ML Reference secrets ==="

echo "  --- HuggingFace Token ---"
HF_TOKEN_DECODED=""

if [[ -n "$HF_SECRET_SOURCE_NS" ]] && kubectl get secret "$HF_SECRET_SOURCE_NAME" -n "$HF_SECRET_SOURCE_NS" &>/dev/null; then
  echo "  [source] Reading HF token from secret $HF_SECRET_SOURCE_NAME in $HF_SECRET_SOURCE_NS"
  HF_TOKEN_VALUE=$(kubectl get secret "$HF_SECRET_SOURCE_NAME" -n "$HF_SECRET_SOURCE_NS" \
    -o jsonpath='{.data.HF_TOKEN}' 2>/dev/null || \
    kubectl get secret "$HF_SECRET_SOURCE_NAME" -n "$HF_SECRET_SOURCE_NS" \
    -o jsonpath='{.data.token}' 2>/dev/null)
  HF_TOKEN_DECODED=$(echo "$HF_TOKEN_VALUE" | base64 -d 2>/dev/null || echo "$HF_TOKEN_VALUE")
elif [[ -n "${HF_TOKEN:-}" ]]; then
  echo "  [source] Reading HF token from HF_TOKEN environment variable"
  HF_TOKEN_DECODED="$HF_TOKEN"
else
  echo "  [WARN] No HuggingFace token found. Skipping."
fi

if [[ -n "$HF_TOKEN_DECODED" ]]; then
  for ns in "${GENERATIVE_NAMESPACES[@]}"; do
    if kubectl get secret "$HF_SECRET_NAME" -n "$ns" &>/dev/null; then
      echo "  [exists] $HF_SECRET_NAME in $ns: updating"
      kubectl delete secret "$HF_SECRET_NAME" -n "$ns"
    fi
    kubectl create secret generic "$HF_SECRET_NAME" -n "$ns" \
      --from-literal=HF_TOKEN="$HF_TOKEN_DECODED"
    kubectl annotate secret "$HF_SECRET_NAME" -n "$ns" \
      serving.kserve.io/secretKey=HF_TOKEN --overwrite
    echo "  [created] $HF_SECRET_NAME in $ns"
  done
fi

echo "  --- Container Registry ---"
REGISTRY_SECRET_NAME="registry-cred"

if [[ -n "${REGISTRY_SERVER:-}" && -n "${REGISTRY_USERNAME:-}" && -n "${REGISTRY_PASSWORD:-}" ]]; then
  for ns in "${ALL_NAMESPACES[@]}"; do
    if kubectl get secret "$REGISTRY_SECRET_NAME" -n "$ns" &>/dev/null; then
      kubectl delete secret "$REGISTRY_SECRET_NAME" -n "$ns"
    fi
    kubectl create secret docker-registry "$REGISTRY_SECRET_NAME" -n "$ns" \
      --docker-server="${REGISTRY_SERVER}" \
      --docker-username="${REGISTRY_USERNAME}" \
      --docker-password="${REGISTRY_PASSWORD}"
    echo "  [created] $REGISTRY_SECRET_NAME in $ns"
  done
else
  echo "  [skip] No registry credentials provided"
fi

echo "=== Secret setup complete ==="
