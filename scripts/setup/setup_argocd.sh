#!/usr/bin/env bash
# setup_argocd.sh: Install ArgoCD and configure for the ML Reference project
#
# Installs ArgoCD via Helm, applies the AppProject and Applications,
# and port-forwards the ArgoCD UI.
set -euo pipefail

ARGOCD_VERSION="${ARGOCD_VERSION:-7.7.16}"
REPO_URL="${REPO_URL:-https://github.com/AymenSegni/kserve-gitops-blueprint.git}"

echo "=== ML Reference: ArgoCD Setup ==="

# --- Step 1: Install ArgoCD ---
echo "--- Step 1: Install ArgoCD ---"
if kubectl get namespace argocd &>/dev/null; then
  echo "  [exists] ArgoCD namespace exists"
else
  echo "  [installing] ArgoCD ${ARGOCD_VERSION}"
  helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
  helm repo update
  helm install argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --version "${ARGOCD_VERSION}" \
    --set server.service.type=ClusterIP \
    --wait
  echo "  [done] ArgoCD installed"
fi

# --- Step 2: Wait for ArgoCD to be ready ---
echo "--- Step 2: Waiting for ArgoCD server ---"
kubectl wait --for=condition=available deployment/argocd-server \
  -n argocd --timeout=120s

# --- Step 3: Apply AppProject ---
echo "--- Step 3: Applying ArgoCD AppProject ---"
kubectl apply -f argocd/project.yaml
echo "  [done] AppProject 'kserve-gitops-blueprint' created"

# --- Step 4: Apply Applications ---
echo "--- Step 4: Applying ArgoCD Applications ---"
kubectl apply -f argocd/applications/
echo "  [done] Applications created"

# --- Step 5: Get initial admin password ---
echo ""
echo "=== ArgoCD is ready ==="
echo ""
echo "Admin password:"
ADMIN_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "(not found — may have been deleted)")
echo "  $ADMIN_PW"
echo ""
echo "Port-forward the UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  open https://localhost:8080"
echo ""
echo "Login:"
echo "  argocd login localhost:8080 --username admin --password '$ADMIN_PW' --insecure"
