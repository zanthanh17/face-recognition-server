import base64
import os
import sys
import time
from dataclasses import dataclass
from typing import Optional

import cv2
import numpy as np
import requests


@dataclass
class Config:
    server_url: str = os.getenv("SERVER_URL", "http://127.0.0.1:8000")
    device_id: str = os.getenv("DEVICE_ID", "local-pc")
    mode: str = os.getenv("MODE", "recognize")  # "register" or "recognize"
    register_name: str = os.getenv("REGISTER_NAME", "User Local")
    register_position: str = os.getenv("REGISTER_POSITION", "")
    image_path: Optional[str] = os.getenv("IMAGE_PATH")


def image_to_base64(image_bgr: np.ndarray, quality: int = 85) -> str:
    ok, buf = cv2.imencode(".jpg", image_bgr, [int(cv2.IMWRITE_JPEG_QUALITY), quality])
    if not ok:
        raise RuntimeError("Failed to encode image")
    return base64.b64encode(buf.tobytes()).decode("utf-8")


def capture_frame_from_camera(camera_index: int = 0, width: int = 640, height: int = 480) -> Optional[np.ndarray]:
    cap = cv2.VideoCapture(camera_index)
    if not cap.isOpened():
        print("[ERR] Cannot open camera", file=sys.stderr)
        return None
    # Try set resolution
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    time.sleep(0.2)
    ok, frame = cap.read()
    cap.release()
    if not ok or frame is None:
        print("[ERR] Cannot read frame", file=sys.stderr)
        return None
    return frame


def detect_and_crop(image_bgr: np.ndarray) -> np.ndarray:
    gray = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2GRAY)
    cascade_path = cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    face_cascade = cv2.CascadeClassifier(cascade_path)
    faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5)
    h, w = gray.shape[:2]
    if len(faces) == 0:
        # fallback center crop square
        side = min(h, w)
        y0 = (h - side) // 2
        x0 = (w - side) // 2
        crop = image_bgr[y0 : y0 + side, x0 : x0 + side]
    else:
        x, y, ww, hh = max(faces, key=lambda r: r[2] * r[3])
        pad = int(0.15 * max(ww, hh))
        x0 = max(x - pad, 0)
        y0 = max(y - pad, 0)
        x1 = min(x + ww + pad, w)
        y1 = min(y + hh + pad, h)
        crop = image_bgr[y0:y1, x0:x1]
    crop = cv2.resize(crop, (256, 256), interpolation=cv2.INTER_AREA)
    return crop


def post_register(cfg: Config, image_b64: str) -> None:
    url = f"{cfg.server_url}/register"
    payload = {
        "name": cfg.register_name,
        "position": cfg.register_position,
        "image_base64": image_b64,
    }
    r = requests.post(url, json=payload, timeout=10)
    r.raise_for_status()
    print("[REGISTER]", r.json())


def post_recognize(cfg: Config, image_b64: str) -> None:
    url = f"{cfg.server_url}/recognize"
    payload = {
        "image_base64": image_b64,
        "device_id": cfg.device_id,
        "ts": int(time.time()),
    }
    r = requests.post(url, json=payload, timeout=10)
    r.raise_for_status()
    print("[RECOGNIZE]", r.json())


def main() -> None:
    cfg = Config()
    print(f"SERVER_URL={cfg.server_url} MODE={cfg.mode}")
    if cfg.image_path and os.path.exists(cfg.image_path):
        frame = cv2.imread(cfg.image_path)
        if frame is None:
            print(f"[ERR] Cannot read IMAGE_PATH={cfg.image_path}", file=sys.stderr)
            sys.exit(1)
    else:
        frame = capture_frame_from_camera()
    if frame is None:
        print("No frame captured. Exiting.")
        sys.exit(1)
    crop = detect_and_crop(frame)
    img_b64 = image_to_base64(crop, quality=85)

    if cfg.mode.lower() == "register":
        post_register(cfg, img_b64)
    else:
        post_recognize(cfg, img_b64)


if __name__ == "__main__":
    main()


