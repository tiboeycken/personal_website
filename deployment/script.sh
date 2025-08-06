#!/bin/bash

PROJECT_ID=""
BILLING_ACCOUNT_ID=""
REGION="europe-west1"

check_gcloud_installed() {
    if ! command -v gcloud &>/dev/null; then
        echo "Error: Google Cloud CLI (gcloud) is not installed or not in your PATH."
        echo "Please follow the installation instructions here: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

choose_project() {
    # Get array of project IDs
    IFS=$'\n' read -r -d '' -a PROJECTS < <(gcloud projects list --format="get(projectId)" && printf '\0')
    echo "Choose an existing project or create a new one:"
    local i=0

    # Loop through existing projects
    for PROJECT in "${PROJECTS[@]}"; do
        echo "$i. $PROJECT"
        i=$((i+1))
    done
    
    # Option to create a new project
    echo "$i. new project"

    # Read index chosen by user
    read -p "Number: " INDEX

    # Check users choise
    if [[ $INDEX -eq $i ]]; then
        new_project
    else
        PROJECT_ID=$(echo "${PROJECTS[$INDEX]}" | tr -d '\r\n')
        gcloud config set project "$PROJECT_ID"
    fi
}

new_project() {
    read -p "Project name:" PROJECT_NAME
    gcloud projects create "$PROJECT_NAME"
    PROJECT_ID="$PROJECT_NAME"
    echo "Project created: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
}

choose_billing_account() {
    # Get array of billing account names
    IFS=$'\n' 
    read -d '' -r -a ACCOUNTS <<< "$(gcloud billing accounts list --format="get(displayName)")"
    read -d '' -r -a ACCOUNT_IDS <<< "$(gcloud billing accounts list --format="get(name)")"

    i=0
    echo "Choose a billing account:"

    # Loop through existing projects
    for ACCOUNT in "${ACCOUNTS[@]}"; do
        echo "$i. $ACCOUNT"
        i=$((i+1))
    done

    # Read index chosen by user
    read -p "Number: " INDEX

    # Check users choise
    if [[ $INDEX -ge $i ]]; then
        echo "This is not a valid choise, stopping script"
        exit 1
    fi

    BILLING_ACCOUNT_ID=$(echo "${ACCOUNT_IDS[$INDEX]}" | tr -d '\r\n')
    link_billing_to_project
}

link_billing_to_project(){
    echo "Linking $PROJECT_ID to $BILLING_ACCOUNT_ID"
    gcloud beta billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID" 2>&1
    if [ $? -eq 1 ]; then
        echo "Error linking billing account"
    else
        echo "Billing account linked succesfully"
    fi
}

# This function will be used solely to get the project number to give permissions to the service account
get_project_number(){
    gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)"
}

create_and_set_custom_role(){
    local PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")
    local SERVICE_ACCOUNT_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com"

    # Enable required APIs
    gcloud services enable secretmanager.googleapis.com cloudbuild.googleapis.com run.googleapis.com

    # CUSTOMROLEGCPSA="customRoleGCPSA"
    # CUSTOMROLECB="customeRoleCB"

    # gcloud iam roles create $CUSTOMROLEGCPSA \
    #     --project="$PROJECT_ID" \
    #     --title="Custom Role for GCP SA Service Account" \
    #     --permissions="secretmanager.secrets.create,secretmanager.secrets.setIamPolicy,secretmanager.secrets.getIamPolicy" \
    #     --stage=GA

    # gcloud iam roles create $CUSTOMROLECB \
    #     --project="$PROJECT_ID" \
    #     --title="Custom Role for CB Service Account" \
    #     --permissions="secretmanager.versions.add" \
    #     --stage=GA

    # Custom SA used by the Build Trigger - used to build and deploy Images to Cloud Build
    gcloud iam service-accounts create cloud-build-deployer \
        --description="SA for Cloud Build deployments" \
        --display-name="Cloud Build Deployer"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/run.admin"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountUser"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/logging.logWriter"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/storage.admin"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/cloudbuild.builds.builder"

    # gcloud projects add-iam-policy-binding $PROJECT_ID \
    #     --member="serviceAccount:cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
    #     --role="roles/serviceusage.serviceUsageConsumer"

    # Needed to create the github connection - needs secretmanager.secrets.create - maybe more
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
            --role="roles/secretmanager.admin" 2>&1 >/dev/null

    #     gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    #         --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
    #         --role="roles/run.admin" 2>&1 >/dev/null

    # gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    #     --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    #     --role="projects/$PROJECT_ID/roles/$CUSTOMROLECB" 2>&1 >/dev/null

    # gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    #     --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    #     --role="roles/iam.serviceAccountUser"

    # gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    #     --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    #     --role="roles/cloudbuild.builds.editor"

    USER_EMAIL=$(gcloud config get-value account)

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="user:$USER_EMAIL" \
        --role="roles/secretmanager.admin"


    echo "Custom role created and assigned to $SERVICE_ACCOUNT_EMAIL"
}


conn_gh_repo(){
    # service-account will need roles   "roles/secretmanager.secrets.setIamPolicy";"roles/secretmanager.secrets.create"
    # Will need the user to authenticate with github 
    CONNECTION_NAME="github_connection"
    GITHUB_REPO="https://github.com/tiboeycken/personal_website.git"
    gcloud builds connections create github $CONNECTION_NAME --region="$REGION"

    echo "First choose your google account associated with the cloud project, then log into github where the repo is located."
   
    # Guessing I need to put a loop here to check if it has been properly linked or not
    # Spinner setup
    SPINNER=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    i=0
    MAX_RETRIES=60
    RETRY=0

    while [[ "$(gcloud builds connections describe "$CONNECTION_NAME" --region="$REGION" --format='value(installationState.stage)')" != "COMPLETE" ]]; do
        if [[ $RETRY -ge $MAX_RETRIES ]]; then
            echo -e "\nTimeout waiting for GitHub connection to be authorized."
            exit 1
        fi

        printf "\r${SPINNER[$i]} Waiting for authorization... (%d/%d)" "$RETRY" "$MAX_RETRIES"
        i=$(( (i+1) % ${#SPINNER[@]} ))
        sleep 1
        ((RETRY++))
    done

    echo -e "\rGitHub connection authorized successfully!"

    # After this we should create the repo in gcloud
    gcloud beta builds repositories create personal_website \
        --region="$REGION" \
        --connection="$CONNECTION_NAME" \
        --remote-uri="$GITHUB_REPO"
}

setup_gcrun_trigger(){
    local PROJECT_NUMBER=$(get_project_number "$PROJECT_ID")
    local REPO="personal_website" # Name of the repo in gcloud -> `gcloud builds repositories list --region=$REGION --connection=$CONNECTION`

    # Correct command - differs from what is stated in the documentation
    gcloud builds triggers create github \
        --name="deploy" \
        --repository="projects/$PROJECT_ID/locations/$REGION/connections/$CONNECTION_NAME/repositories/$REPO" \
        --branch-pattern="^main$" \
        --region="$REGION" \
        --service-account="projects/$PROJECT_ID/serviceAccounts/cloud-build-deployer@$PROJECT_ID.iam.gserviceaccount.com" \
        --build-config="cloudbuild.yaml"

    gcloud builds triggers run deploy --region="$REGION" --branch="main"
}

check_gcloud_installed
choose_project
choose_billing_account
create_and_set_custom_role
conn_gh_repo
setup_gcrun_trigger