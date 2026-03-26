# KServe Features Reference

This document annotates every KServe feature used in this reference project, with links to upstream documentation and the corresponding manifest in this repo.

## InferenceService (Predictive)

**What**: Deploy ML models as autoscaling Kubernetes services using KServe's V2 Open Inference Protocol.

**Where**: [`kserve/predictive/`](../kserve/predictive/)

| Feature | Manifest | Description |
|---------|----------|-------------|
| Custom container predictor | `resnet50-isvc.yaml` | Run your own model server with V2 protocol |
| Knative KPA autoscaling | `resnet50-isvc.yaml` | Scale 0→N based on request concurrency |
| Health probes | `resnet50-isvc.yaml` | `/v2/health/ready` and `/v2/health/live` |
| Prometheus scraping | All ISVCs | `serving.kserve.io/enable-prometheus-scraping: "true"` |

**Docs**: [KServe InferenceService](https://kserve.github.io/website/docs/model-serving/generative-inference/overview)

---

## InferenceService (Generative)

**What**: Serve LLMs via KServe's built-in HuggingFace runtime with vLLM backend.

**Where**: [`kserve/generative/mistral-isvc.yaml`](../kserve/generative/mistral-isvc.yaml)

| Feature | Manifest | Description |
|---------|----------|-------------|
| HuggingFace runtime | `mistral-isvc.yaml` | Built-in runtime for HF models |
| vLLM backend | `mistral-isvc.yaml` | `--backend=vllm` for high-throughput LLM serving |
| Storage initializer | `mistral-isvc.yaml` | Auto-download model from HF Hub |

**Docs**: [KServe HuggingFace Runtime](https://kserve.github.io/website/docs/model-serving/generative-inference/overview)

---

## LLMInferenceService (v0.17+)

**What**: A new CRD (`serving.kserve.io/v1alpha1`) specifically designed for LLM deployments. Simplifies LLM serving by directly orchestrating Deployments, Services, and networking.

**Where**: [`kserve/generative/mistral-llmisvc.yaml`](../kserve/generative/mistral-llmisvc.yaml)

| Feature | Description |
|---------|-------------|
| `modelUri` | Direct HF model reference (`hf://...`) |
| `workerSpec` | GPU resources, tensor parallelism, env vars |
| `replicas` | Direct replica count management |
| `routerConfig` | Optional request distribution router |

> **Note**: `LLMInferenceService` is in alpha (`v1alpha1`). For production, the standard `InferenceService` with HuggingFace runtime remains fully supported.

**Docs**: [KServe LLMInferenceService](https://kserve.github.io/website/docs/model-serving/generative-inference/overview)

---

## Autoscaling

**Where**: [`kserve/autoscaling/`](../kserve/autoscaling/)

| Autoscaler | Manifest | Metric |
|------------|----------|--------|
| **Knative KPA** | `resnet50-isvc.yaml` | Request concurrency |
| **KEDA** | `mistral-realtime-isvc.yaml`, `keda-mistral.yaml` | vLLM active requests (Prometheus) |

**Docs**: [KServe Autoscaling](https://kserve.github.io/website/docs/model-serving/autoscaling/autoscaling/)

---

## InferenceGraph

**What**: Chain multiple InferenceServices into a DAG pipeline.

**Where**: [`kserve/graphs/ml-pipeline-graph.yaml`](../kserve/graphs/ml-pipeline-graph.yaml)

| Router Type | Description |
|-------------|-------------|
| **Ensemble** | Run multiple models in parallel, merge results |
| **Sequence** | Pass output of one model to the next |

**Docs**: [KServe InferenceGraph](https://kserve.github.io/website/docs/model-serving/inference-graph/overview)

---

## LocalModelCache

**What**: Pre-download model weights to node local storage for faster cold starts.

**Where**: [`kserve/generative/local-model-cache.yaml`](../kserve/generative/local-model-cache.yaml)

Requires KServe v0.14+ with the LocalModelCache alpha feature gate enabled.

---

## Canary Rollout

**What**: Gradually roll out new model versions by splitting traffic between stable and canary revisions.

**Where**: [`kserve/canary/resnet50-canary-isvc.yaml`](../kserve/canary/resnet50-canary-isvc.yaml)

---

## Custom Model Servers (V2 Protocol)

**What**: Build your own model server implementing the V2/Open Inference Protocol.

**Where**: [`models/`](../models/)

| Component | File | Description |
|-----------|------|-------------|
| `preprocess()` | `model.py` | Decode input (base64 images, text) |
| `predict()` | `model.py` | Run model inference |
| `postprocess()` | `model.py` | Format as `InferResponse` |
