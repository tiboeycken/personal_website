# Sets Terraform Settings
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# Sets provider's settings/variables
provider "google" {
  project = var.project
  region  = var.region
}

# Enabling multiple APIs to access the secretmanager, cloudbuild and cloud run
resource "google_project_service" "gcp_services" {
  project  = var.project
  for_each = toset(var.gcp_service_list)
  service  = each.key
}

# Creating custom SA used to create the github connection, cloud repo and build trigger
resource "google_service_account" "sa" {
  account_id   = "cloud-build-deployer"
  display_name = "Cloud Build Service Account"
  description  = "SA for Cloud Build Deployments"
}

# Roles to use cloud run, logging, buckets to store images and builder to build the images
resource "google_project_iam_member" "custom_sa_roles" {
  project  = var.project
  for_each = toset(var.custom_sa_roles)
  role     = each.key
  member   = "serviceAccount:${google_service_account.sa.email}"
}

# Project number needed later to assign role to default SA
data "google_project" "current" {
  project_id = var.project
}

# Roles for default SA to add and read github PAT --- admin might be too much  
resource "google_project_iam_member" "gcp_sa_roles" {
  project = var.project
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
}

# Adding secrets needed by the Trigger later - following https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloudbuildv2_connection#example-usage---cloudbuildv2-connection-github
resource "google_secret_manager_secret" "github-token-secret" {
  secret_id = "github-token-secret"

  replication {
    auto {}
  }
  depends_on = [google_project_service.gcp_services]
}

# PAT needed by the trigger to access our repository
resource "google_secret_manager_secret_version" "github-token-secret-version" {
  secret      = google_secret_manager_secret.github-token-secret.id
  secret_data = file("my-github-token.txt")
  depends_on  = [google_project_service.gcp_services]
}

// Connection allowing us to connect to our repository
resource "google_cloudbuildv2_connection" "my_connection" {
  location = var.region
  name     = "github_connection"
  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github-token-secret-version.id
    }
  }

  depends_on = [google_project_service.gcp_services]
}

# Used to declare which gh repo we want to use
resource "google_cloudbuildv2_repository" "my_repository" {
  location          = var.region
  name              = "my_repo"
  parent_connection = google_cloudbuildv2_connection.my_connection.name
  remote_uri        = var.github_repo
}

# Deploys our application each time a push is made 
resource "google_cloudbuild_trigger" "deploy" {
  name     = "deploy"
  location = var.region

  repository_event_config {
    repository = google_cloudbuildv2_repository.my_repository.id
    push {
      branch = "^main$"
    }
  }

  filename        = "deployment/cloudbuild.yaml"
  service_account = google_service_account.sa.name
}