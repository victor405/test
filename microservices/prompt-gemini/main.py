import os
import json
import boto3
import pymysql
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------- DB ----------
def get_db():
    secret_arn = os.environ["DB_SECRET_ARN"]
    region = os.environ["AWS_REGION"]

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
    import requests
    api_key = os.environ.get("GEMINI_API_KEY")

    if not api_key:
        return f"Echo: {prompt}"

    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key={api_key}"

    body = {
        "contents": [
            {"parts": [{"text": prompt}]}
        ]
    }

    r = requests.post(url, json=body, timeout=10)

    if r.status_code != 200:
        return f"Gemini error: {r.status_code} - {r.text}"

    data = r.json()

    return data["candidates"][0]["content"]["parts"][0]["text"]

# ---------- Routes ----------

@app.get("/health")
def health():
    try:
        conn = get_db()
        conn.close()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "error", "error": str(e)}

@app.post("/prompt")
def prompt(data: dict):
    prompt_text = data.get("prompt", "")

    answer = ask_gemini(prompt_text)

    conn = get_db()
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO prompt_history (prompt, answer) VALUES (%s, %s)",
            (prompt_text, answer)
        )
        conn.commit()
    conn.close()

    return {
        "prompt": prompt_text,
        "answer": answer
    }
# ---------- API GATEWAY : Prompt History ----------
def get_history():
    try:
        url = "http://prompt-history.prompt-history/history"
        r = requests.get(url, timeout=5)

        if r.status_code != 200:
            return {"error": f"history service error: {r.status_code}"}

        return r.json()

    except Exception as e:
        return {"error": str(e)}

@app.get("/history")
def history():
    return get_history()