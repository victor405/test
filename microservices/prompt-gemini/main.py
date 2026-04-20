import os
import json
import logging
import boto3
import pymysql
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ddtrace import patch_all
import ddtrace

# ---------- Datadog APM ----------
patch_all()

ddtrace.config.service = "prompt-gemini"
ddtrace.config.env = "dev"
ddtrace.config.version = "1.0"

# ---------- Logging ----------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ---------- App ----------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://victor405.github.io"
    ],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- DB ----------
def get_db():
    secret_arn = os.environ["DB_SECRET_ARN"]
    region = os.environ["AWS_REGION"]

    logger.info("Fetching DB credentials")

    sm = boto3.client("secretsmanager", region_name=region)
    secret = json.loads(sm.get_secret_value(SecretId=secret_arn)["SecretString"])

    rds = boto3.client("rds", region_name=region)
    endpoint = rds.describe_db_instances()["DBInstances"][0]["Endpoint"]["Address"]

    return pymysql.connect(
        host=endpoint,
        user=secret["username"],
        password=secret["password"],
        database="demodb",
        connect_timeout=5
    )

# ---------- Gemini ----------
def ask_gemini(prompt: str) -> str:
    api_key = os.environ.get("GEMINI_API_KEY")

    if not api_key:
        return f"Echo: {prompt}"

    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={api_key}"

    body = {
        "contents": [
            {"parts": [{"text": prompt}]}
        ]
    }

    try:
        r = requests.post(url, json=body, timeout=10)

        if r.status_code != 200:
            logger.error(f"Gemini error: {r.status_code} - {r.text}")
            return f"Gemini error: {r.status_code}"

        data = r.json()

        return data.get("candidates", [{}])[0] \
            .get("content", {}) \
            .get("parts", [{}])[0] \
            .get("text", "No response")

    except Exception as e:
        logger.error(f"Gemini exception: {str(e)}")
        return "Gemini request failed"

# ---------- Routes ----------

@app.get("/health")
def health():
    try:
        conn = get_db()
        conn.close()
        return {"status": "ok"}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return {"status": "error", "error": str(e)}

@app.post("/prompt")
def prompt(data: dict):
    prompt_text = data.get("prompt", "")

    logger.info(f"Prompt received: {prompt_text}")

    answer = ask_gemini(prompt_text)

    try:
        conn = get_db()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO prompt_history (prompt, answer) VALUES (%s, %s)",
                (prompt_text, answer)
            )
            conn.commit()
        conn.close()
    except Exception as e:
        logger.error(f"DB insert failed: {str(e)}")

    return {
        "prompt": prompt_text,
        "answer": answer
    }

@app.get("/history")
def history():
    try:
        conn = get_db()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, prompt, answer, created_at
                FROM prompt_history
                ORDER BY id DESC
                LIMIT 50
            """)
            rows = cur.fetchall()
        conn.close()

        rows.reverse()

        return {"history": rows}

    except Exception as e:
        logger.error(f"History fetch failed: {str(e)}")
        return {"error": str(e)}

