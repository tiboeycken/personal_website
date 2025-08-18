# 🛠️ Cloud Run Bash Deployment

This script automates the deployment of a personal GitHub repository using a**Terraform** script.

## Prerequisites

- A Google Cloud account with an existing project linked to a Billing Account.
- Access to a personal GitHub repo containing:
    - Your application code
    - A deployment/ folder with necessary deployment configs
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed
- The [Google Cloud Build GitHub App](https://cloud.google.com/build/docs/automating-builds/github/build-repos-from-github?generation=2nd-gen) installed on your GitHub repository.

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
1. Clone the repo
```bash
git clone https://www.github.com/tiboeycken/personal_website.git
cd personal_website/deployment/terraform
```

2. Prepare GitHub token
Terraform needs a **Github Personal Access Token (PAT)** to access your repo.
- Create a PAT in GitHub with `repo` and `read:user` permissions
- Save it in a file named `my-github-token.txt` in the same folder as your Terraform scripts

3. Configure GitHub App
Copy the Installation ID from the Google Cloud Build GitHub app (found in the URL of the configure page)

4. Set your variables
fill in the ´terraform.tfvars` file with your values
```bash
billing_account            = "<BILLING_ACCOUNT_ID>"
project                    = "<PROJECT_ID>"
admin_email                = "<YOUR_GCP_USER_EMAIL>"
github_repo                = "https://github.com/<user>/<repo>.git"
github_app_installation_id = "<INSTALLATION_ID>"
```

5. Initialize Terraform
```bash
cd terraform
teraform init
```

6. Deploy infrastructure
```bash
terraform plan      # Verify installation
terraform apply      
```

## 🧠 What Terraform Does

1. Enable Required APIs
    - Secret Manager
    - Cloud Build
    - Cloud Run

2. Create Service Account
    - 'cloud-build-deployer' with roles:
        - ´roles/run.admin´
        - ´roles/iam.serviceAccountUser´
        - ´roles/logging.admin´
        - ´roles/storage.admin´
        - ´roles/cloudbuilds.builds.builder´
        - ´roles/secretmanager.admin´

3. Setup Secrets
    - Creates a Secret Manager secret to hold your GitHub token 

4. Connect Github
    - Creates a Cloud Build connection to your repo
    - Adds a build trigger that runs on pushes to the 'main' branch

5. Deploy to Cloud Run
    - Builds a Docker image via Cloud Build
    - Pushes to Google Artifact Registry
    - Deploys the container to Cloud Run

## 🧹 Cleanup

To destroy all resources

```bash
terraform destroy
```