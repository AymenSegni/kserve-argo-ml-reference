#!/usr/bin/env python3
import argparse
import base64
import io
import json
import sys
import numpy as np
import requests
from PIL import Image

def create_test_image(size=(224, 224)) -> str:
    arr = np.zeros((*size, 3), dtype=np.uint8)
    arr[:, :, 0] = np.linspace(0, 255, size[0])[:, None]
    arr[:, :, 1] = np.linspace(0, 255, size[1])[None, :]
    arr[:, :, 2] = 128
    img = Image.fromarray(arr)
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")

def test_resnet50(host: str, namespace: str = "ml-predictive") -> bool:
    print("\n=== Testing ResNet-50 ===")
    url = f"http://{host}/v2/models/resnet50/infer"
    headers = {
        "Host": f"resnet50-predictor.{namespace}.svc.cluster.local",
        "Content-Type": "application/json",
    }
    payload = {
        "inputs": [{
            "name": "input-0",
            "datatype": "BYTES",
            "shape": [1],
            "data": [create_test_image()],
        }]
    }
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        outputs = {o["name"]: o for o in resp.json()["outputs"]}
        predictions = json.loads(outputs["predictions"]["data"][0])
        print(f"  [PASS] Got {len(predictions)} predictions")
        return True
    except Exception as e:
        print(f"  [FAIL] {e}")
        return False

def test_sentence_bert(host: str, namespace: str = "ml-predictive") -> bool:
    print("\n=== Testing Sentence-BERT ===")
    url = f"http://{host}/v2/models/sentence-bert/infer"
    headers = {
        "Host": f"sentence-bert-predictor.{namespace}.svc.cluster.local",
        "Content-Type": "application/json",
    }
    texts = ["KServe makes ML model serving easy.", "ArgoCD provides GitOps."]
    payload = {
        "inputs": [{
            "name": "input-0",
            "datatype": "BYTES",
            "shape": [len(texts)],
            "data": texts,
        }]
    }
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        outputs = {o["name"]: o for o in resp.json()["outputs"]}
        print(f"  [PASS] Got embeddings, shape={outputs['embeddings']['shape']}")
        return True
    except Exception as e:
        print(f"  [FAIL] {e}")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost:8081")
    parser.add_argument("--namespace", default="ml-predictive")
    args = parser.parse_args()
    results = [test_resnet50(args.host, args.namespace), test_sentence_bert(args.host, args.namespace)]
    sys.exit(0 if all(results) else 1)
