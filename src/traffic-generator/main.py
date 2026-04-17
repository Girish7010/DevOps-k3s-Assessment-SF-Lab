import time
import random
import requests
import os

API_URL = os.getenv("API_URL", "http://sample-api.sample-api.svc.cluster.local:80")

ENDPOINTS = [
    {"method": "GET", "path": "/"},
    {"method": "GET", "path": "/health"},
    {"method": "GET", "path": "/items/1"},
    {"method": "GET", "path": "/items/2"},
    {"method": "GET", "path": "/items/0"}, # 404
    {"method": "POST", "path": "/items", "body": {"name": "test", "price": 10.5}},
    {"method": "POST", "path": "/items", "body": {"name": "test-bad", "price": -5}}, # 400
    {"method": "GET", "path": "/error"} # 500
]

print(f"Starting traffic generator against {API_URL}...")

while True:
    endpoint = random.choice(ENDPOINTS)
    url = f"{API_URL}{endpoint['path']}"
    try:
        if endpoint["method"] == "GET":
            response = requests.get(url, timeout=2)
        elif endpoint["method"] == "POST":
            response = requests.post(url, json=endpoint["body"], timeout=2)
        print(f"[{endpoint['method']}] {url} - {response.status_code}")
    except Exception as e:
        print(f"Failed to call {url}: {e}")
        
    time.sleep(random.uniform(0.5, 3.0))
