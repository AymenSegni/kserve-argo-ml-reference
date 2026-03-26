#!/usr/bin/env python3
import argparse
import sys
import requests

def test_mistral_endpoint(host: str, isvc_name: str, namespace: str = "ml-generative") -> bool:
    print(f"\n=== Testing {isvc_name} ===")
    url = f"http://{host}/openai/v1/chat/completions"
    headers = {
        "Host": f"{isvc_name}-predictor.{namespace}.svc.cluster.local",
        "Content-Type": "application/json",
    }
    payload = {
        "model": "mistral-7b",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "What is KServe?"},
        ],
        "max_tokens": 50,
        "temperature": 0.1,
    }
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=120)
        resp.raise_for_status()
        result = resp.json()
        content = result["choices"][0]["message"]["content"]
        print(f"  [PASS] Response received ({len(content)} chars)")
        return True
    except requests.exceptions.Timeout:
        print(f"  [FAIL] Request timed out (120s) — model may be loading")
        return False
    except Exception as e:
        print(f"  [FAIL] {e}")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="localhost:8081")
    parser.add_argument("--namespace", default="ml-generative")
    parser.add_argument("--endpoint", default="both", choices=["batch", "realtime", "both"])
    args = parser.parse_args()
    
    eps = ["mistral-batch", "mistral-realtime"] if args.endpoint == "both" else [f"mistral-{args.endpoint}"]
    results = [test_mistral_endpoint(args.host, ep, args.namespace) for ep in eps]
    sys.exit(0 if all(results) else 1)
