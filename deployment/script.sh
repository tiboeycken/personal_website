#!/bin/bash

PROJECT_ID=""
BILLING_ACCOUNT_ID=""
REGION="europe-west1"
REPO_NAME="personal_website"
REPO_OWNER="tiboeycken"

APIS_TO_ENABLE=(
    cloudbuild.googleapis.com
    run.googleapis.com
    secretmanager.googleapis.com
)

check_gcloud_installed() {
    if ! command -v gcloud &>/dev/null; then
        echo "Error: Google Cloud CLI (gcloud) is not installed or not in your PATH."
        echo "Please follow the installation instructions here: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

choose_project() {
    # Get array of project IDs
    IFS=$'\n' 
    read -d '' -r -a PROJECTS <<< "$(gcloud projects list --format="get(projectId)")"
    i=0
    echo "Choose an existing project or create a new one:"

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
        PROJECT_ID=${PROJECTS[$INDEX]}
    fi
}

new_project() {
    read -p "Project name: " PROJECT_NAME
#    gcloud projects create "$PROJECT_NAME"
    $PROJECT_ID="$PROJECT_NAME"
    echo "Project created: $PROJECT_ID"
}

choose_billing_account() {
    # Get array of project IDs
    local IFS=$'\n' 
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

    BILLING_ACCOUNT_ID=${ACCOUNT_IDS[$INDEX]}
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
    local PERMISSIONS_FOR_GCP_SA_CB="secretmanager.secrets.create,secretmanager.secrets.setIamPolicy"
    local PERMISSIONS_FOR_CB="run.admin,iam.serviceAccountUser"

    gcloud iam roles create GCPSACBCustomRole \
        --project="$PROJECT_ID" \
        --title="Custom Role for GCP SA CB Service Account" \
        --permissions="$PERMISSIONS_FOR_GCP_SA_CB" \
        --stage=GA

    gcloud iam roles create CB_CustomRole \
        --project="$PROJECT_ID" \
        --title="Custom Role for CB Service Account" \
        --permissions="$PERMISSIONS_FOR_CB" \
        --stage=GA 

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
            --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com" \
            --role="projects/$PROJECT_ID/roles/GCPSACBCustomRole" 2>&1 >/dev/null

    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
        --role="projects/$PROJECT_ID/roles/CB_CustomRole" 2>&1 >/dev/null


    echo "Custom role created and assigned to $SERVICE_ACCOUNT_EMAIL"
}


link_gh_repo(){
    # service-account will need roles   "roles/secretmanager.secrets.setIamPolicy";"roles/secretmanager.secrets.create"
    # Will need the user to authenticate with github 
    gcloud builds connections create github github_connection --region="$REGION"
}

setup_gcrun_trigger(){
gcloud builds triggers create \
  --name="deploy-on-push" \
  --region="europe-west1" \
  --repository="projects/PROJECT_ID/locations/europe-west1/connections/github_connection/repositories/personal_website" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild.yaml"

}

check_gcloud_installed
choose_project
choose_billing_account
create_and_set_custom_role
link_gh_repo
setup_gcrun_trigger