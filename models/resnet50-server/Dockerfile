FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY model.py /app/model.py

# Download weights during build
ENV TORCH_HOME=/app/.torch
RUN python -c "from torchvision.models import resnet50, ResNet50_Weights; resnet50(weights=ResNet50_Weights.DEFAULT)"
RUN chmod -R 777 /app/.torch

USER 1000:1000

ENTRYPOINT ["python", "/app/model.py"]
