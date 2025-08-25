FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 libgl1 ca-certificates curl g++ && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install server dependencies (full, includes deepface)
COPY server/requirements.txt /app/server/requirements.txt
RUN pip install --upgrade pip && pip install -r /app/server/requirements.txt && \
    pip uninstall -y opencv-python && pip install opencv-python-headless==4.10.0.84 && \
    pip install insightface onnxruntime

# Copy source
COPY server /app/server
COPY scripts /app/scripts

EXPOSE 8000

ENV HOST=0.0.0.0 \
    PORT=8000 \
    RECOGNITION_THRESHOLD=0.45 \
    DEEPFACE_MODEL=ArcFace

CMD ["python", "scripts/start_server.py"]


