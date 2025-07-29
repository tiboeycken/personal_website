#!/bin/bash

check_gcloud_installed() {
    if ! command -v gcloud &>/dev/null; then
        echo_in_red "Error: Google Cloud CLI (gcloud) is not installed or not in your PATH."
        echo "Please follow the installation instructions here: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
}

enable_apis() {
    echo_in_blue "Enabling necessary Google Cloud APIs..."
    for API in "${APIS_TO_ENABLE[@]}"; do
        echo "  Enabling API: $API"
        gcloud services enable "$API" --project="$PROJECT_ID" 2>&1
        if [ $? -ne 0 ]; then
            echo_in_red "Error enabling API '$API'."
            echo "Please check the output above for details."
            exit 1
        fi
    done
    echo_in_green "All necessary APIs enabled successfully."
}

set_default_region_zone() {
    if [[ -n "$DEFAULT_REGION" ]]; then
        echo_in_blue "Setting default Compute Region to '$DEFAULT_REGION'..."
        gcloud config set compute/region "$DEFAULT_REGION" --project="$PROJECT_ID"
        if [ $? -eq 0 ]; then
            echo_in_green "Default Compute Region set."
        else
            echo_in_yellow "Failed to set default Compute Region."
        fi
    fi

    if [[ -n "$DEFAULT_ZONE" ]]; then
        echo_in_blue "Setting default Compute Zone to '$DEFAULT_ZONE'..."
        gcloud config set compute/zone "$DEFAULT_ZONE" --project="$PROJECT_ID"
        if [ $? -eq 0 ]; then
            echo_in_green "Default Compute Zone set."
        else
            echo_in_yellow "Failed to set default Compute Zone."
        fi
    fi
}

set_default_region_zone() {
    if [[ -n "$DEFAULT_REGION" ]]; then
        echo_in_blue "Setting default Compute Region to '$DEFAULT_REGION'..."
        gcloud config set compute/region "$DEFAULT_REGION" --project="$PROJECT_ID"
        if [ $? -eq 0 ]; then
            echo_in_green "Default Compute Region set."
        else
            echo_in_yellow "Failed to set default Compute Region."
        fi
    fi

    if [[ -n "$DEFAULT_ZONE" ]]; then
        echo_in_blue "Setting default Compute Zone to '$DEFAULT_ZONE'..."
        gcloud config set compute/zone "$DEFAULT_ZONE" --project="$PROJECT_ID"
        if [ $? -eq 0 ]; then
            echo_in_green "Default Compute Zone set."
        else
            echo_in_yellow "Failed to set default Compute Zone."
        fi
    fi
}

