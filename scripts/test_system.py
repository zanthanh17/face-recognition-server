import base64
import json
import os
import time
from pathlib import Path
from typing import List

import cv2
import numpy as np
import requests


SERVER_URL = os.getenv("SERVER_URL", "http://127.0.0.1:8000")


def to_b64(img):
    ok, buf = cv2.imencode(".jpg", img, [int(cv2.IMWRITE_JPEG_QUALITY), 85])
    assert ok
    return base64.b64encode(buf.tobytes()).decode("utf-8")


def run_latency_test(n: int = 5) -> None:
    cam = cv2.VideoCapture(0)
    cam.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cam.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    times: List[float] = []
    for i in range(n):
        ok, frame = cam.read()
        if not ok:
            continue
        t0 = time.time()
        payload = {"image_base64": to_b64(frame), "device_id": "local-test", "ts": int(time.time())}
        r = requests.post(f"{SERVER_URL}/recognize", json=payload, timeout=10)
        r.raise_for_status()
        dt = (time.time() - t0) * 1000
        times.append(dt)
        print(f"[{i+1}/{n}] {dt:.1f} ms -> {r.json()}")
    cam.release()
    if times:
        p50 = np.percentile(times, 50)
        p95 = np.percentile(times, 95)
        print(json.dumps({"p50_ms": float(p50), "p95_ms": float(p95)}, indent=2))


if __name__ == "__main__":
    run_latency_test(5)


