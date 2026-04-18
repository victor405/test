from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai
import mysql.connector
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai-microservice")

app = FastAPI(title="AI Microservice")

client = genai.Client(api_key=os.environ["GEMINI_API_KEY"])


class AnalyzeRequest(BaseModel):
    text: str


def get_db_connection():
    return mysql.connector.connect(
        host=os.environ["DB_HOST"],
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        connection_timeout=5,
    )


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/db-check")
def db_check():
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT 1;")
        result = cursor.fetchone()
        cursor.close()
        conn.close()

        return {"db": "ok", "result": result[0]}

    except Exception as e:
        logger.exception("Database check failed")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ai/analyze")
def analyze(request: AnalyzeRequest):
    prompt = f"""
    Analyze this text briefly.

    Return:
    - summary
    - sentiment
    - operational_risk

    Text:
    {request.text}
    """

    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash-lite",
            contents=prompt,
        )

        answer = response.text or ""

        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            """
            INSERT INTO ai_prompt_answers (prompt, answer)
            VALUES (%s, %s);
            """,
            (request.text, answer),
        )

        conn.commit()
        row_id = cursor.lastrowid

        cursor.close()
        conn.close()

        logger.info("Saved Gemini response to RDS. id=%s", row_id)

        return {
            "id": row_id,
            "model": "gemini-2.5-flash-lite",
            "prompt": request.text,
            "analysis": answer,
            "saved_to_rds": True,
        }

    except Exception as e:
        logger.exception("AI analyze request failed")
        raise HTTPException(status_code=500, detail=str(e))