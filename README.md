# 🚀 Automated Cloud Run deployment

This repository provides multiple ways to deploy your GitHub repository to Google Cloud Run:
- Using Terraform to automate project setup
- Using Bash/PowerShell scripts

---

## 📌 Overview

- Automates GCP project creation or selection, billing setup, API enablement, and service accounts.
- Integrates your GitHub repository with Google Cloud Build.
- Deploys your application to Cloud Run with auto-scaling to 0 to minimize costs.
- Supports both Linux/macOS (Bash) and Windows (PowerShell).

---

## ✨ Features

- ✅ Full GCP project automation with Terraform
- ✅ Cloud Build triggers connected to GitHub repository
- ✅ Automatic Docker build & deployment to Cloud Run
- ✅ Secret management using Secret Manager for GitHub PAT
- ✅ Supports both Bash and PowerShell deployment scripts
- ✅ Auto-scaling Cloud Run services

---

## 🛠️ Technologies & Tools

- Languages: Bash, PowerShell, Terraform
- Tools: Docker, Git, Google Cloud SDK
- Services: Cloud Run, Cloud Build, IAM, Secret Manager

---

## 📦 Setup & Installation

1. CLone the Repository
```bash
# Clone the repository
git clone https://github.com/tiboeycken/personal_website.git
cd personal_website
```

2a. Terraform Deployment
Terraform automates the full setup:
1. Prepare a GitHub Personal Access Token (PAT) and save it as my-github-token.txt in deployment/terraform.
2. Create a terraform.tfvars file in deployment/terraform:

```bash
billing_account            = "<BILLING_ACCOUNT_ID>"
project                    = "<PROJECT_ID>"
admin_email                = "<YOUR_GCP_USER_EMAIL>"
github_repo                = "https://github.com/<user>/<repo>.git"
github_app_installation_id = "<INSTALLATION_ID>"
```

```bash
cd deployment/terraform
terraform init
terraform plan
terraform apply
```

2b. Bash/PowerShell Scripts
```bash
# Bash
./deployment/scripts/deploy.sh 

# PowerShell
./deployment/scripts/deploy.ps1
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
│   ├── scripts/
│   │   ├── deploy.sh          # Bash deployment script
│   │   ├── deploy.ps1         # PowerShell deployment script
│   ├── terraform/
│   │   ├── .gitignore
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   ├── variables.tf
│   │   ├── README.md
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
