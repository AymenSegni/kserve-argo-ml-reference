FROM python:3.11-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

WORKDIR /app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

COPY model.py /app/model.py

# Pre-download model into image
ENV HF_HOME=/app/.cache
RUN python -c "from transformers import AutoModel, AutoTokenizer; m='sentence-transformers/all-MiniLM-L6-v2'; AutoTokenizer.from_pretrained(m); AutoModel.from_pretrained(m)"
RUN chmod -R 777 /app/.cache

USER 1000:1000

ENTRYPOINT ["python", "/app/model.py"]
