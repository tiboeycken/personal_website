variable "project" {}

variable "billing_account" {}

variable "admin_email" {}

variable "github_repo" {}

variable "github_app_installation_id" {}

variable "region" {
  default = "europe-west1"
}

variable "gcp_service_list" {
  description = "The list of apis necessary for the project"
  type        = list(string)
  default = [
    "secretmanager.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com"
  ]
}

variable "custom_sa_roles" {
  description = "The list of roles the custom SA needs"
  type        = list(string)
  default = [
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/logging.admin",
    "roles/storage.admin",
    "roles/cloudbuild.builds.builder"
  ]
}