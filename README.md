# 🚀 Automated Cloud Run deployment

Scripts to deploy your GitHub repository to Cloud Run using gcloud CLI.

---

## 📌 Overview

This repository contains both a bash and powershell script which will connect your GitHub repository to Google Cloud Build and deploy it to Cloud Run.

---

## ✨ Features

- 🔧 Automated setup of GCP project, billing link, APIs, and service accounts
- ⚙️ Creates a Cloud Build trigger linked to your GitHub repository
- ☁️ Deploys to Cloud Run with auto-scaling to 0 for cost savings
- 🖥️ Works with both Bash (Linux/Mac) and PowerShell (Windows)

---

## 🛠️ Technologies & Tools

- Languages: Bash, PowerShell
- Tools: Docker, Git, Google Cloud SDK
- Services: Cloud Run, Cloud Build, IAM, Secret Manager

---

## 📦 Setup & Installation

```bash
# Clone the repository
git clone https://github.com/tiboeycken/personal_website.git
cd personal_website

# Run setup script or follow manual steps
bash ./deployment/script.sh
```

> Important: Your GitHub repository must include:
>-    deployment/cloudbuild.yaml
>-   deployment/Dockerfile
>-   Any application files (e.g., webapp/) required by the Docker build.
>-   These files are sent to Google Cloud Build when triggered.

---

## 🔄 Deployment Workflow

1. Script creates/links your GCP project & billing account
2. Enables required APIs (run.googleapis.com, cloudbuild.googleapis.com, etc.)
3. Creates and configures a cloud-build-deployer service account
4. Connects your GitHub repo to Google Cloud Build
5. Sets up a trigger for automatic deployment on push to main

---

## 📁 Folder Structure

```text
.
├── deployment/
│   ├── deploy.sh          # Bash deployment script
│   ├── deploy.ps1         # PowerShell deployment script
│   ├── cloudbuild.yaml    # Cloud Build configuration
│   ├── Dockerfile         # Container build definition
│   ├── nginx.conf         # Nginx config
│   └── README.md          # More specific run instructions
├── webapp/                # Application files served by Nginx
├── .gitignore             # Files ignored by git
└── README.md

```

---

## 🙋‍♂️ Author

Made with ☕ and a little help from AI  
**Tibo Eycken** – [GitHub](https://github.com/tiboeycken) · [LinkedIn](https://www.linkedin.com/in/tiboeycken/)
