# 🛠️ Cloud Run Bash Deployment

This script automates the deployment of a personal GitHub repository using **Cloud Build** and **Cloud Run**, via a single Bash script.

## Prerequisites

- [Google Cloud SDK (gcloud)](https://cloud.google.com/sdk/docs/install) installed and authenticated.- A Google Cloud account with an existing Billing Account.
- Access to a personal GitHub repo containing:
    - Your application code
    - A deployment/ folder with necessary deployment configs

## 📁 Project Structure Requirement
Your GitHub repository **must include** the following structure:
```bash
your-repo/
├── deployment/
│   ├── cloudbuild.yaml     # Cloud Build configuration
│   ├── Dockerfile          # Dockerfile used by Cloud Build
└── webapp/                 # Static files to be served
```
> ⚠️ Cloud Build expects both `cloudbuild.yaml` and `Dockerfile` in the `deployment/` folder.

## 🚀 How to Run
Run the script:
```bash
cd deployment/scripts
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

## 🧹 Cleanup

To clean up the resources (project, services, roles), you will need to manually:

- Delete the Cloud Run service
- Remove the Cloud Build trigger
- Delete the GCP project (optional)