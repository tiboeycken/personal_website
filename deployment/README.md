# 🛠️ Cloud Run Bash Deployment

This script automates the deployment of a personal GitHub repository using **Cloud Build** and **Cloud Run**, via a single Bash script.

## Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated.
- A Google Cloud account with an existing Billing Account.
- Access to a personal GitHub repo.

## 🚀 How to Run

```bash
cd deployment
./deploy.sh
```

## 🧠 What the Script Does

1. GCP Project Setup
    - Lists existing projects for selection or creates a new one        
    - Sets the selected project as active in gcloud

2. Billing Account Linking
    - Prompts selection of a billing account
    - Links it to the selected project

3. API Enablement
    - Enables the following APIs:
        secretmanager.googleapis.com
        cloudbuild.googleapis.com
        run.googleapis.com

4. Service Account Creation
    - Creates a cloud-build-deployer service account
    - Assigns necessary IAM roles:
        roles/run.admin
        roles/iam.serviceAccountUser
        roles/logging.admin
        roles/storage.admin
        roles/cloudbuild.builds.builder
        roles/secretmanager.admin

5. GitHub Integration
    - Prompts you to authenticate with GitHub
    - Creates a Cloud Build connection to your repo
    - Creates a Cloud Build trigger that deploys on main branch pushes

6. Cloud Run Deployment
    - Builds Docker image using deployment/Dockerfile
    - Pushes to Google Container Registry
    - Deploys it to Cloud Run

## 📁 Project Structure
```bash
.
├── deployment/
│   ├── deploy.sh           # Main deployment script
│   ├── Dockerfile          # Dockerfile used by Cloud Build
│   ├── cloudbuild.yaml     # Cloud Build configuration
│   └── README.md           # You're here!
└── webapp/                 # Static files to be served
```

## 📝 Notes
- This script is opinionated and tailored for static websites, but can be modified for other use cases.
- The script assumes a basic NGINX-based Docker deployment. You can customize the Dockerfile and cloudbuild.yaml for other frameworks (e.g., Node.js, Flask, etc.).