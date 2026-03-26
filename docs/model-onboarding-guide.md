# Model Onboarding Guide

Step-by-step guide for adding a new model to the KServe + ArgoCD ML Reference platform.

## Overview

To add a new model, you need:
1. A model server (custom container or built-in runtime)
2. A KServe InferenceService or LLMInferenceService manifest
3. An ArgoCD Application (optional, if using a new namespace)

## Step 1: Build the Model Server

### Option A: Custom Container (V2 Protocol)

Use this for models that need custom pre/post-processing. Create a new directory under `models/` and extend `kserve.Model` in `model.py`.

### Option B: Built-in Runtime

Use KServe's built-in runtimes (HuggingFace, Triton, SKLearn, XGBoost).

## Step 2: Create Manifest

Create a YAML file in `kserve/predictive/` or `kserve/generative/`. ArgoCD will automatically pick it up and deploy it.

## Step 3: Commit and Sync

Commit the file and push to trigger ArgoCD.

## Step 4: Validate

Use KServe's `status.url` to send a test payload to the /v2/models/<model_name>/infer endpoint.
