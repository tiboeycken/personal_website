#!/bin/bash

# Config - alter this to your specific needs
REGION="europe-west1"
GITHUB_REPO="https://github.com/tiboeycken/personal_website.git"
REPO_NAME="personal_website"
CONNECTION_NAME="github_connection"

# UTILS
log() { echo -e "\nLOG: $1"; }
err() { echo -e "\nERROR: $1" >&2; exit 1; }

# STEP 0: Check if gcloud CLI is installed
check_gcloud_installed() {
    if ! command -v gcloud &>/dev/null; then
        err "Google Cloud SDK (gcloud) not found. Install: https://cloud.google.com/sdk/docs/install"
    fi
}

# STEP 1: Choose or create a project
choose_project() {
    # Get array of project IDs
    log "Fetching GCP projects..."
    IFS=$'\n' read -r -d '' -a PROJECTS < <(gcloud projects list --format="get(projectId)" && printf '\0')

    echo "Choose an existing project or create a new one:"
    local i=0
    for PROJECT in "${PROJECTS[@]}"; do
        echo "$i. $PROJECT"
        i=$((i+1))
    done
    echo "$i. new project"
    read -p "Number: " INDEX

    if [[ $INDEX -eq $i ]]; then
        read -p "New project ID: " PROJECT_ID
        gcloud projects create "$PROJECT_ID"
    else
        PROJECT_ID=$(echo "${PROJECTS[$INDEX]}" | tr -d '\r\n')
    fi
    
    gcloud config set project "$PROJECT_ID"
    export PROJECT_ID
}

# STEP 2: Choose billing account
choose_billing_account() {
    # Get array of billing account names
    log "Selecting billing account..."
    IFS=$'\n' read -r -d '' -a ACCOUNTS < <(gcloud billing accounts list --format="get(displayName)" && printf '\0')
    IFS=$'\n' read -r -d '' -a ACCOUNT_IDS < <(gcloud billing accounts list --format="get(name)" && printf '\0')

    for i in "${!ACCOUNTS[@]}"; do
        echo "$i. ${ACCOUNTS[$i]}"
    done
    read -p "Number: " CHOISE

    [[ $CHOISE -ge ${#ACCOUNTS[@]} ]] && err "Invalid selection."

    BILLING_ACCOUNT_ID=$(echo "${ACCOUNT_IDS[$CHOISE]}" | tr -d '\r\n')
    gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID" 2>&1
}

# STEP 3: Create and configure service account
service_account_and_roles(){
    log "Creating service account and assigning roles..."

    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
    GCP_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    CUSTOM_SA_EMAIL="cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com"

    gcloud services enable secretmanager.googleapis.com cloudbuild.googleapis.com run.googleapis.com

    # Custom SA used by the Build Trigger - used to build and deploy Images to Cloud Build
    gcloud iam service-accounts create cloud-build-deployer \
        --description="SA for Cloud Build deployments" \
        --display-name="Cloud Build Deployer"

    until gcloud iam service-accounts describe "$CUSTOM_SA_EMAIL" >/dev/null 2>&1; do
        echo "Waiting for service account to become available..."
        sleep 2
    done

    for ROLE in run.admin iam.serviceAccountUser logging.admin storage.admin cloudbuild.builds.builder; do
        gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$CUSTOM_SA_EMAIL" \
            --role="roles/$ROLE"
    done

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:$GCP_SA_EMAIL" \
            --role="roles/secretmanager.admin"

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="user:$(gcloud config get-value account)" \
        --role="roles/secretmanager.admin"
}

# STEP 4: Connect to GitHub
connect_github_repo(){
    log "Connecting to GitHub repo..." 

    gcloud builds connections create github $CONNECTION_NAME --region="$REGION"

    echo "Follow prompts to authenticate with GitHub."
   
    # Spinner while waiting for connection to complete
    SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    i=0; retry=0; max=60

    while [[ "$(gcloud builds connections describe "$CONNECTION_NAME" --region="$REGION" --format='value(installationState.stage)')" != "COMPLETE" ]]; do
        [[ $retry -ge $max ]] && err "Timeout waiting for GitHub auth" 
        printf "\r${SPINNER[$i]} Waiting for authorization... (%d/%d)" "$retry" "$max"
        sleep 1
        i=$(( (i+1) % ${#SPINNER[@]} ))
        ((retry++))
    done

    echo -e "\rGitHub connection authorized successfully!"

    # After this we should create the repo in gcloud
    gcloud beta builds repositories create "$REPO_NAME" \
        --region="$REGION" \
        --connection="$CONNECTION_NAME" \
        --remote-uri="$GITHUB_REPO"
}

# STEP 5: Set up Cloud Build trigger
setup_build_trigger(){
    log "Setting up Cloud Build trigger..."

    gcloud builds triggers create github \
        --name="deploy" \
        --repository="projects/$PROJECT_ID/locations/$REGION/connections/$CONNECTION_NAME/repositories/$REPO_NAME" \
        --branch-pattern="^main$" \
        --region="$REGION" \
        --service-account="projects/$PROJECT_ID/serviceAccounts/cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --build-config="cloudbuild.yaml"

    gcloud builds triggers run deploy --region="$REGION" --branch="main"
}

check_gcloud_installed
choose_project
choose_billing_account
service_account_and_roles
connect_github_repo
setup_build_trigger