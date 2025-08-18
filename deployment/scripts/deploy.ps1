# Config - alter to your specific needs
$region = "europe-west1"
$githubRepo = "https://github.com/tiboeycken/personal_website.git"
$repoName = "personal_website"
$connectionName = "github_connection"

# UTILS
function Log($msg) {
    Write-Host "`nLOG: $msg"
}

function Err($msg) {
    Write-Host "`nERROR: $msg"
    exit 1
}

function Check-GCloudInstalled {
    if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
        Err "Google Cloud SDK (gcloud) not found. Install: https://cloud.google.com/sdk/docs/install"
    }
}

function Choose_Project {
    Log "Fetching GCP projects..."
    $projects = gcloud projects list --format="get(projectId)"
    $projectsList = $projects -split '`n'

    Write-Host "Use an existing Google Project or create a new one"
    for ($i = 0; $i -lt $projectsList.Count; $i++) {
        Write-Host "$i. $($projectsList[$i])"
    }
    $newIndex = $projectsList.Count
    Write-Host "$newIndex. new project"
    $choise = Read-Host "Number: "

    if ($choise -eq $newIndex) {
        $projectId = Read-Host "New project ID"
        gcloud projects create $projectId
    }
    else {
        $projectId = $projectsList[$choise]
    }

    gcloud config set project $projectId | Out-Null
    $script:projectId = $projectId
}

function Choose_BillingAccount {
    Log "Selecting Billing Account..."
    $accounts = gcloud billing accounts list --format="get(displayName)" 
    $account_Ids = gcloud billing accounts list --format="get(name)"

    $accountArray = $accounts -split '`n'
    $accountIdArray = $account_Ids -split '`n'

    for ($i = 0; $i -lt $accountArray.Count; $i++) {
        Write-Host "$i. $($accountArray[$i])"
    }
    $choise = Read-Host "Number: "
    
    if ($choise -ge $accountArray.Count) {
        Err "Invalid selection."
    }

    $billing_account_id = $accountIdArray[$choise]
    gcloud beta billing projects link "$projectId" --billing-account="$billing_account_id" 
}

function Service_Account_And_Roles {
    Log "Creating service account and assigning roles..."

    $projectNumber = gcloud projects describe "$projectId" --format="value(projectNumber)"
    $gcpSaEmail = "service-$projectNumber@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    $customSaEmail = "cloud-build-deployer@$projectId.iam.gserviceaccount.com"

    gcloud services enable secretmanager.googleapis.com cloudbuild.googleapis.com run.googleapis.com

    gcloud iam service-accounts create cloud-build-deployer `
        --description="SA for Cloud Build deployments" `
        --display-name="Cloud Build Deployer"

    do {
        Write-Host "Waiting for service account to become available..."
        Start-Sleep -Seconds 2
    } until (
        gcloud iam service-accounts describe "$customSaEmail"
    )

    $roles = @(
        "run.admin",
        "iam.serviceAccountUser",
        "logging.admin",
        "storage.admin",
        "cloudbuild.builds.builder"
    )

    foreach ($role in $roles) {
        gcloud projects add-iam-policy-binding "$projectId" `
            --member="serviceAccount:$customSaEmail" `
            --role="roles/$ROLE"    
    }

    gcloud projects add-iam-policy-binding "$projectId" `
        --member="serviceAccount:$gcpSaEmail" `
        --role="roles/secretmanager.admin"

    $userEmail = gcloud config get-value account
    gcloud projects add-iam-policy-binding "$projectId" `
        --member="user:$userEmail" `
        --role="roles/secretmanager.admin"
}

function Connect_Github_Repo {
    Log "Connecting to GitHub repo..."

    gcloud builds connections create github $connectionName --region="$region"

    Write-Host "Follow prompts to authenticate with GitHub."

    $retry = 0
    $max = 60

    while ($(gcloud builds connections describe "$connectionName" --region="$region" --format='value(installationState.stage)') -ne "COMPLETE") {
        if ($retry -ge $max ) {
            Err "Timeout waiting for Github auth"
        }
        Write-Host "Waiting for authorization... ($retry/$max)"
        Start-Sleep -Seconds 1
        $retry++
    }

    Write-Host "GitHub connection authorized successfully!"

    gcloud beta builds repositories create $repoName `
        --region=$region `
        --connection=$connectionName `
        --remote-uri=$githubRepo
}

function Setup_Build_Trigger {
    Log "Setting up Cloud Build trigger..."

    gcloud builds triggers create github `
        --name="deploy" `
        --repository="projects/$projectId/locations/$region/connections/$connectionName/repositories/$repoName" `
        --branch-pattern="^main$" `
        --region="$region" `
        --service-account="projects/$projectId/serviceAccounts/cloud-build-deployer@$projectId.iam.gserviceaccount.com" `
        --build-config="deployment/cloudbuild.yaml"

    gcloud builds triggers run deploy --region="$region" --branch="main"
}

Check-GCloudInstalled
Choose_Project
Choose_BillingAccount
Service_Account_And_Roles
Connect_Github_Repo
Setup_Build_Trigger