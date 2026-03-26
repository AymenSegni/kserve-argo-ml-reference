# kserve-gitops-blueprint

A production-grade GitOps blueprint for deploying generative and predictive AI on Kubernetes using **KServe**, **vLLM**, and **ArgoCD**.

## What this is

A community reference architecture demonstrating how to deploy, operate, and scale ML/LLM models on Kubernetes. Uses open-source models and covers the most important KServe features.

**Models deployed:**

| Model | Type | Purpose | Runtime |
|-------|------|---------|---------|
| **ResNet-50** | Predictive | Image classification | Custom KServe server |
| **Sentence-BERT** | Predictive | Text embeddings | Custom KServe server |
| **Mistral-7B-Instruct** | Generative | Chat completion | KServe HF runtime / vLLM |

## KServe Features Covered

| Feature | Example |
|---------|---------|
| InferenceService (predictive) | ResNet-50, Sentence-BERT |
| InferenceService (generative) | Mistral-7B + vLLM |
| LLMInferenceService (v0.17+) | Simplified LLM CRD (`v1alpha1`) |
| Custom KServe Model Server (V2) | `models/resnet50-server/`, `models/sentence-bert-server/` |
| Knative Autoscaling (KPA) | Scale 0→N on concurrency |
| KEDA Autoscaling | Scale on vLLM concurrency metrics |
| InferenceGraph | Ensemble + Sequence pipeline |
| LocalModelCache | Pre-download LLM to node NVMe |
| Canary Rollout | 90/10 traffic split |
| ArgoCD GitOps | Auto-sync, self-heal, retry |
| Prometheus Monitoring | ServiceMonitors + alerting rules |

> 📖 For detailed explanations of each feature with links to upstream KServe docs, see the [KServe Features Reference](docs/kserve-features-reference.md). To add your own models, follow the [Model Onboarding Guide](docs/model-onboarding-guide.md).

## Quick Start

### 1. Install Control Plane

```bash
bash scripts/setup/setup_controlplane.sh
```

### 2. Create Namespaces & Secrets

```bash
bash scripts/setup/setup_namespaces.sh
export HF_TOKEN="hf_your_token_here"
bash scripts/setup/setup_secrets.sh
```

### 3. Deploy via ArgoCD

```bash
bash scripts/setup/setup_argocd.sh
```

ArgoCD will auto-sync all manifests. View the UI at `localhost:8080`.

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `scripts/setup/setup_controlplane.sh` | Install Istio, Knative, KServe, KEDA |
| `scripts/setup/setup_namespaces.sh` | Create ml-* namespaces |
| `scripts/setup/setup_secrets.sh` | Distribute HF token + registry creds |
| `scripts/setup/setup_argocd.sh` | Install ArgoCD + deploy apps |
| `scripts/validate/validate_predictive.sh` | Validate predictive ISVCs |
| `scripts/validate/validate_generative.sh` | Validate generative ISVCs |
| `scripts/smoke/smoke_test_predictive.py` | End-to-end test: ResNet-50 + SBERT |
| `scripts/smoke/smoke_test_generative.py` | End-to-end test: Mistral-7B |

## License

Apache 2.0 — see [LICENSE](LICENSE).
