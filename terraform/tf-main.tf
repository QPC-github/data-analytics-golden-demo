####################################################################################
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
####################################################################################

####################################################################################
# README
# This is the main entry point into the Terraform creation script
# This script can be run in a different ways:
#  1. Run "source deploy.sh" in the root folder (this for for when you run locally or cloud shell).
#     This will create the GCP project for you and deploy everything.  The logged in user needs to be
#     an Org Admin so the project can be created and permissions set.
#
#  2. If you have a GCP project already created you would run just by passing in the parameters.
#     Review the script deploy-use-existing-project.sh to see the requirements of what is
#     required items and permissions.
#     terraform apply \
#       -var="gcp_account_name=${gcp_account_name}" \
#       -var="project_id=${project_id}" \
#       -var="project_number=${project_number}" \
#       -var="deployment_service_account_name=${service_account_email}" \
#       -var="org_id=${org_id}"
#
# Review the parameters.  If a Project Number is passed in, it is assumed the GCP project has been created.
#
# Author: Adam Paternostro
#
# References:
# Terraform for Google: https://registry.terraform.io/providers/hashicorp/google/latest/docs
#                       https://www.terraform.io/language/resources/provisioners/local-exec
####################################################################################


terraform {
  required_providers {
    google = {
      source                = "hashicorp/google-beta"
      version               = "4.42.0"
      configuration_aliases = [google.service_principal_impersonation]
    }
  }
}


####################################################################################
# Variables (Set in the ../terraform.tfvars.json file) or passed viw command line
####################################################################################

# CONDITIONS: (Always Required)
variable "gcp_account_name" {
  type        = string
  description = "This is the name of the user who be running the demo.  It is used to set security items. (e.g. admin@mydomain.com)"
  validation {
    condition     = length(var.gcp_account_name) > 0
    error_message = "The gcp_account_name is required."
  }
}


# CONDITIONS: (Always Required)
variable "project_id" {
  type        = string
  description = "The GCP Project Id/Name or the Prefix of a name to generate (e.g. data-analytics-demo-xxxxxxxxxx)."
  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id is required."
  }
}


# CONDITIONS: (Only If) a GCP Project has already been created.  Otherwise it is not required.
variable "project_number" {
  type        = string
  description = "The GCP Project Number"
  default     = ""
}


# CONDITIONS: (Only If) you have a service account doing the deployment (from DevOps)
variable "deployment_service_account_name" {
  type        = string
  description = "The name of the service account that is doing the deployment.  If empty then the script is creatign a service account."
  default     = ""
}


# CONDITIONS: (Always Required)
variable "org_id" {
  type        = string
  description = "This is org id for the deployment"
  default     = ""
  validation {
    condition     = length(var.org_id) > 0
    error_message = "The org_id is required."
  }
}


# CONDITIONS: (Only If) the project_number is NOT provided and Terraform will be creating the GCP project for you
variable "billing_account" {
  type        = string
  description = "This is the name of the user who the deploy is for.  It is used to set security items for the user/developer. (e.g. admin@mydomain.com)"
  default     = ""
}


# CONDITIONS: (Optional) unless you want a different region/zone
variable "region" {
  type        = string
  description = "The GCP region to deploy."
  default     = "us-west2"
  validation {
    condition     = length(var.region) > 0
    error_message = "The region is required."
  }
}

variable "zone" {
  type        = string
  description = "The GCP zone in the region. Must be in the region."
  default     = "us-west2-a"
  validation {
    condition     = length(var.zone) > 0
    error_message = "The zone is required."
  }
}

variable "spanner_config" {
  type        = string
  description = "This should be a spanner config in the region.  See: https://cloud.google.com/spanner/docs/instance-configurations#available-configurations-multi-region"
  default     = "nam8"
  validation {
    condition     = length(var.spanner_config) > 0
    error_message = "The spanner_config is required."
  }
}

variable "bigquery_region" {
  type        = string
  description = "The GCP region to deploy BigQuery.  This should either match the region or be 'us' or 'eu'.  This also affects the GCS bucket and Data Catalog."
  default     = "us"
  validation {
    condition     = length(var.bigquery_region) > 0
    error_message = "The region is required."
  }
}

########################################################################################################
# Google specific values (you need to setup your own OMNI)
########################################################################################################
variable "shared_demo_project_id" {
  type        = string
  description = "The name of a shared project that holds the OMNI slots and other sample data "
  default     = "REPLACE_ME_SHARED_DEMO_PROJECT_ID"
}

variable "aws_omni_biglake_dataset_region" {
  type        = string
  description = "The region of AWS OMNI"
  default     = "aws-us-east-1"
}

variable "aws_omni_biglake_dataset_name" {
  type        = string
  description = "The dataset to hold the AWS procedures and tables"
  default     = "aws_omni_biglake"
}

variable "aws_omni_biglake_connection" {
  type        = string
  description = "The AWS connection name"
  default     = "bq_omni_aws_s3"
}

variable "aws_omni_biglake_s3_bucket" {
  type        = string
  description = "The name of the S3 bucket"
  default     = "REPLACE_ME_AWS_S3_BUCKET_NAME"
}

variable "azure_omni_biglake_adls_name" {
  type        = string
  description = "The name of the S3 bucket"
  default     = "REPLACE_ME_AZURE_ADLS_NAME"
}

variable "azure_omni_biglake_dataset_name" {
  type        = string
  description = "The name of the Azure dataset"
  default     = "azure_omni_biglake"
}

variable "azure_omni_biglake_dataset_region" {
  type        = string
  description = "The region of Azure OMNI"
  default     = "azure-eastus2"
}


########################################################################################################
# Some deployments target different environments
########################################################################################################
variable "environment" {
  type        = string
  description = "Where is the script being run from.  Internal system or public GitHub"
  default     = "GITHUB_ENVIRONMENT" #_REPLACEMENT_MARKER (do not remove this text of change the spacing)
}


########################################################################################################
# Not required for this demo, but is part of click to deploy automation
########################################################################################################
variable "data_location" {
  type        = string
  description = "Location of source data file in central bucket"
  default     = ""
}
variable "secret_stored_project" {
  type        = string
  description = "Project where secret is accessing from"
  default     = ""
}
variable "project_name" {
  type        = string
  description = "Project name in which demo deploy"
  default     = ""
}


####################################################################################
# Local Variables 
####################################################################################

# Create a random string for the project/bucket suffix
resource "random_string" "project_random" {
  length  = 10
  upper   = false
  lower   = true
  numeric = true
  special = false
}

locals {
  # The project is the provided name OR the name with a random suffix
  local_project_id = var.project_number == "" ? "${var.project_id}-${random_string.project_random.result}" : var.project_id

  # Apply suffix to bucket so the name is unique
  local_storage_bucket = "${var.project_id}-${random_string.project_random.result}"

  # Use the GCP user or the service account running this in a DevOps process
  local_impersonation_account = var.deployment_service_account_name == "" ? "user:${var.gcp_account_name}" : length(regexall("^serviceAccount:", var.deployment_service_account_name)) > 0 ? "${var.deployment_service_account_name}" : "serviceAccount:${var.deployment_service_account_name}"

  local_curl_impersonation = var.environment == "GITHUB_ENVIRONMENT" ? "--impersonate-service-account=${var.deployment_service_account_name}" : ""

  # Make sure you use a Federated Identity: https://cloud.google.com/bigquery/docs/omni-azure-create-connection#federated-identity
  local_azure_omni_biglake_connection = "projects/${var.shared_demo_project_id}/locations/${var.azure_omni_biglake_dataset_region}/connections/bq_omni_azure_adlsgen2 "
}


####################################################################################
# Providers
# Multiple providers: https://www.terraform.io/language/providers/configuration
# The first is the default (who is logged in) and creates the project and service principal that provisions the resources
# The second is the service account created by the first and is used to create the resources
####################################################################################
# Default provider (uses the logged in user to create the project and service principal for deployment)
provider "google" {
  project = local.local_project_id
}


# Provider that uses service account impersonation (best practice - no exported secret keys to local computers)
provider "google" {
  alias                       = "service_principal_impersonation"
  impersonate_service_account = "${local.local_project_id}@${local.local_project_id}.iam.gserviceaccount.com"
  project                     = local.local_project_id
  region                      = var.region
  zone                        = var.zone
}


####################################################################################
# Reuseable Modules
####################################################################################
module "project" {
  # Run this as the currently logged in user or the service account (assuming DevOps)
  count           = var.project_number == "" ? 1 : 0
  source          = "../terraform-modules/project"
  project_id      = local.local_project_id
  org_id          = var.org_id
  billing_account = var.billing_account
}


module "service-account" {
  # This creates a service account to run portions of the following deploy by impersonating this account
  source                = "../terraform-modules/service-account"
  project_id            = local.local_project_id
  org_id                = var.org_id
  impersonation_account = local.local_impersonation_account 
  gcp_account_name      = var.gcp_account_name
  environment           = var.environment

  depends_on = [
    module.project
  ]
}


# Enable all the cloud APIs that will be used by using Batch Mode
# Batch mode is enabled on the provider (by default)
module "apis-batch-enable" {
  source = "../terraform-modules/apis-batch-enable"

  project_id                      = local.local_project_id
  project_number                  = var.project_number == "" ? module.project[0].output-project-number : var.project_number
  deployment_service_account_name = var.deployment_service_account_name  

  depends_on = [
    module.project,
    module.service-account
  ]
}

resource "time_sleep" "service_account_api_activation_time_delay" {
  create_duration = "120s"
  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable
  ]  
}


# Uses the new Org Policies method (when a project is created by TF)
module "org-policies" {
  count  = var.environment == "GITHUB_ENVIRONMENT" ? 1 : 0
  source = "../terraform-modules/org-policies"

  # Use Service Account Impersonation for this step. 
  # NOTE: This step must be done using a service account (a user account cannot change these policies)
  providers = { google = google.service_principal_impersonation }

  project_id = local.local_project_id

  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay
  ]
}


# Uses the "Old" Org Policies methods (for when a project is created in advance)
# This is used since the method you cannot specify a project and some orgs deploy with a 
# cloud build account that is in a different domain/org
/*
module "org-policies-deprecated" {
  count  = var.project_number == "" ? 0 : 1
  source = "../terraform-modules/org-policies-deprecated"

  # Use Service Account Impersonation for this step. 
  providers = { google = google.service_principal_impersonation }

  project_id = local.local_project_id

  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay
  ]
}
*/

module "resources" {
  source = "../terraform-modules/resources"

  # Use Service Account Impersonation for this step. 
  providers = { google = google.service_principal_impersonation }

  gcp_account_name                  = var.gcp_account_name
  project_id                        = local.local_project_id
  region                            = var.region
  zone                              = var.zone
  storage_bucket                    = local.local_storage_bucket
  spanner_config                    = var.spanner_config
  random_extension                  = random_string.project_random.result
  project_number                    = var.project_number == "" ? module.project[0].output-project-number : var.project_number
  deployment_service_account_name   = var.deployment_service_account_name
  bigquery_region                   = var.bigquery_region
  curl_impersonation                = local.local_curl_impersonation
  aws_omni_biglake_dataset_region   = var.aws_omni_biglake_dataset_region
  aws_omni_biglake_dataset_name     = var.aws_omni_biglake_dataset_name
  azure_omni_biglake_dataset_name   = var.azure_omni_biglake_dataset_name
  azure_omni_biglake_dataset_region = var.azure_omni_biglake_dataset_region

  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay,
    module.org-policies,
  ]
}


####################################################################################
# Deploy BigQuery stored procedures / sql scripts
###################################################################################
module "sql-scripts" {
  source = "../terraform-modules/sql-scripts"

  # Use Service Account Impersonation for this step. 
  providers = { google = google.service_principal_impersonation }

  gcp_account_name                = var.gcp_account_name
  project_id                      = local.local_project_id
  region                          = var.region
  zone                            = var.zone
  storage_bucket                  = local.local_storage_bucket
  random_extension                = random_string.project_random.result
  project_number                  = var.project_number == "" ? module.project[0].output-project-number : var.project_number
  deployment_service_account_name = var.deployment_service_account_name
  bigquery_region                 = var.bigquery_region
  shared_demo_project_id          = var.shared_demo_project_id
  aws_omni_biglake_dataset_name   = var.aws_omni_biglake_dataset_name
  aws_omni_biglake_dataset_region = var.aws_omni_biglake_dataset_region
  aws_omni_biglake_connection     = var.aws_omni_biglake_connection
  aws_omni_biglake_s3_bucket      = var.aws_omni_biglake_s3_bucket
  azure_omni_biglake_dataset_name = var.azure_omni_biglake_dataset_name
  azure_omni_biglake_connection   = local.local_azure_omni_biglake_connection
  azure_omni_biglake_adls_name    = var.azure_omni_biglake_adls_name

  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay,
    module.org-policies,
    module.resources
  ]
}


# Deploy Dataform
module "dataform-module" {
  source = "../terraform-modules/dataform"

  # Use Service Account Impersonation for this step. 
  providers = { google = google.service_principal_impersonation }

  project_id         = local.local_project_id
  project_number     = var.project_number == "" ? module.project[0].output-project-number : var.project_number
  storage_bucket     = local.local_storage_bucket
  curl_impersonation = local.local_curl_impersonation
  
  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay,
    module.org-policies,
    module.resources
  ]
}


# Upload files and scripts
module "deploy-files-module" {
  source = "../terraform-modules/deploy-files"

  # Use Service Account Impersonation for this step. 
  providers = { google = google.service_principal_impersonation }

  project_id                      = local.local_project_id
  region                          = var.region
  storage_bucket                  = local.local_storage_bucket
  random_extension                = random_string.project_random.result
  deployment_service_account_name = var.deployment_service_account_name
  composer_name                   = module.resources.output-composer-name
  composer_dag_bucket             = module.resources.output-composer-dag-bucket

  depends_on = [
    module.project,
    module.service-account,
    module.apis-batch-enable,
    time_sleep.service_account_api_activation_time_delay,
    module.org-policies,
    module.resources
  ]
}


####################################################################################
# Outputs (Gather from sub-modules)
# Not really needed, but are outputted for viewing
####################################################################################
output "output-project-id" {
  value = local.local_project_id
}

output "output-project-number" {
  value = var.project_number == "" ? module.project[0].output-project-number : var.project_number
}

output "output-region" {
  value = var.region
}

output "output-bucket-name" {
  value = local.local_storage_bucket
}

output "output-composer-name" {
  value = module.resources.output-composer-name
}

output "output-composer-region" {
  value = module.resources.output-composer-region
}

output "output-composer-dag-bucket" {
  value = module.resources.output-composer-dag-bucket
}
