# 🚀 Prompt App (Cloud-Native)

## 🧠 Overview
A lightweight cloud-native application that accepts user prompts, generates responses using Gemini, and stores results in a database. Built with a focus on reliability, scalability, and observability.

---

## 🏗️ Architecture

GitHub Pages (Frontend)
        ↓
Kubernetes Service (LoadBalancer)
        ↓
EKS (FastAPI App)
        ↓
RDS MySQL (private)

---

## ⚙️ Tech Stack

| Layer | Technology |
|------|-----------|
| Frontend | HTML + JavaScript (GitHub Pages) |
| Backend | FastAPI (Python) |
| Container | Docker |
| Orchestration | AWS EKS |
| Database | AWS RDS MySQL |
| IaC | Terraform |
| CI/CD | GitHub Actions |
| Observability | Datadog |

---

## 🚀 Features

- /health → service health check  
- /prompt → send prompt, receive AI response  
- /history → retrieve recent prompts + answers  

---

## 📦 Deployment Flow

Git Push
   ↓
GitHub Actions
   ↓
Docker Build → ECR
   ↓
Helm Deploy → EKS
   ↓
Live Service

---

## 🗄️ Database

Table:

CREATE TABLE prompt_history (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  prompt TEXT NOT NULL,
  answer TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

---

## 📊 Observability

### Metrics
- Kubernetes (nodes, pods, CPU, memory)

### Logs
- Container logs
- Application logs

### APM
- Request tracing via ddtrace

### RUM
- Frontend performance + user interactions

### Uptime Monitoring
- Synthetic checks for frontend endpoints

---

## 🔐 Security

- Secrets stored in AWS Secrets Manager and GitHub Secrets  
- Private RDS (no public access)  
- No hardcoded credentials  

---

## 🧪 Usage

### Health Check

Invoke-RestMethod -Uri "http://<SERVICE_URL>/health"

---

### Send Prompt

$body = @{ prompt = "Hello" } | ConvertTo-Json

Invoke-RestMethod `
  -Uri "http://<SERVICE_URL>/prompt" `
  -Method POST `
  -ContentType "application/json" `
  -Body $body

---

### Frontend

https://victor405.github.io/test

---

## 🎯 Design Principles

- Simple, minimal architecture  
- Fully automated deployments  
- Observable by default  
- Cloud-native and scalable  

---

## 🚀 Future Enhancements

- Autoscaling (HPA)
- Authentication (JWT)
- Rate limiting
- Advanced dashboards
- Multi-region deployment

---

## 👨‍💻 Author

Victor — DevOps / SRE Engineer
