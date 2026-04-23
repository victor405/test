FROM python:3.11-slim

WORKDIR /app

RUN pip install uv

COPY pyproject.toml .
RUN uv pip install --system .

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
#CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
