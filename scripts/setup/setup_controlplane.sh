#!/usr/bin/env bash
# setup_controlplane.sh: Install KServe control plane prerequisites
# Installs (idempotent): Istio, Knative Serving, KServe v0.17+, KEDA
set -euo pipefail

KSERVE_VERSION="${KSERVE_VERSION:-v0.17.0}"
KNATIVE_VERSION="${KNATIVE_VERSION:-v1.15.2}"
KEDA_VERSION="${KEDA_VERSION:-2.17.0}"

echo "=== ML Reference: Control Plane Setup ==="

# --- Step 1: Istio ---
echo "--- Step 1: Istio ---"
if kubectl get namespace istio-system &>/dev/null; then
  echo "  [exists] Istio is already installed"
else
  echo "  [installing] Istio (minimal profile)"
  istioctl install --set profile=minimal -y
fi

# --- Step 2: Knative Serving ---
echo "--- Step 2: Knative Serving ---"
if kubectl get namespace knative-serving &>/dev/null; then
  echo "  [exists] Knative Serving is already installed"
else
  echo "  [installing] Knative Serving ${KNATIVE_VERSION}"
  kubectl apply -f "https://github.com/knative/serving/releases/download/knative-${KNATIVE_VERSION}/serving-crds.yaml"
  kubectl apply -f "https://github.com/knative/serving/releases/download/knative-${KNATIVE_VERSION}/serving-core.yaml"
  kubectl apply -f "https://github.com/knative/net-istio/releases/download/knative-${KNATIVE_VERSION}/net-istio.yaml"
fi

# --- Step 3: KServe ---
echo "--- Step 3: KServe ---"
if kubectl get namespace kserve &>/dev/null || kubectl get crd inferenceservices.serving.kserve.io &>/dev/null; then
  echo "  [exists] KServe already installed"
else
  echo "  [installing] KServe ${KSERVE_VERSION}"
  kubectl apply --server-side -f "https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve.yaml"
  kubectl apply -f "https://github.com/kserve/kserve/releases/download/${KSERVE_VERSION}/kserve-cluster-resources.yaml"
fi

# --- Step 4: KEDA ---
echo "--- Step 4: KEDA ---"
if kubectl get namespace keda &>/dev/null; then
  echo "  [exists] KEDA is already installed"
else
  echo "  [installing] KEDA ${KEDA_VERSION}"
  helm repo add kedacore https://kedacore.github.io/charts 2>/dev/null || true
  helm repo update
  helm install keda kedacore/keda \
    --namespace keda \
    --create-namespace \
    --version "${KEDA_VERSION}" \
    --wait
fi

echo "=== Control plane setup complete ==="
