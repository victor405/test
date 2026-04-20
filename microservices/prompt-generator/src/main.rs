use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use serde::Serialize;
use serde_json::json;
use sqlx::{mysql::MySqlPoolOptions, MySqlPool};
use std::{env, net::SocketAddr};
use tower_http::cors::CorsLayer;

#[derive(Clone)]
struct AppState {
    db: MySqlPool,
}

#[derive(Serialize)]
struct PromptAnswer {
    id: u64,
    prompt: String,
    answer: String,
    created_at: String,
}

#[tokio::main]
async fn main() {
    let db_url = env::var("DATABASE_URL").expect("DATABASE_URL is required");

    let db = MySqlPoolOptions::new()
        .max_connections(5)
        .connect(&db_url)
        .await
        .expect("failed to connect to database");

    let state = AppState { db };

    let app = Router::new()
        .route("/health", get(health))
        .route("/prompts", get(get_prompts))
        .with_state(state)
        .layer(CorsLayer::permissive());

    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    println!("prompt-history listening on {addr}");

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health() -> Json<serde_json::Value> {
    Json(json!({
        "status": "ok",
        "service": "prompt-history"
    }))
}

async fn get_prompts(
    State(state): State<AppState>,
) -> Result<Json<Vec<PromptAnswer>>, (StatusCode, Json<serde_json::Value>)> {
    let rows = sqlx::query_as::<_, (u64, String, String, String)>(
        r#"
        SELECT
          id,
          prompt,
          answer,
          CAST(created_at AS CHAR)
        FROM ai_prompt_answers
        ORDER BY id DESC
        LIMIT 25
        "#,
    )
    .fetch_all(&state.db)
    .await
    .map_err(|err| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({
                "error": "database_error",
                "detail": err.to_string()
            })),
        )
    })?;

    let prompts = rows
        .into_iter()
        .map(|row| PromptAnswer {
            id: row.0,
            prompt: row.1,
            answer: row.2,
            created_at: row.3,
        })
        .collect();

    Ok(Json(prompts))
}