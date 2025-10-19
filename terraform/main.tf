terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "current" {
  count = var.deploy_to_gke ? 1 : 0
}

module "database" {
  count = var.deploy_to_gke ? 1 : 0
  
  source = "./modules/database"
  
  project_id            = var.project_id
  region               = var.region
  environment          = var.environment
  app_name             = var.app_name
  vpc_name             = var.vpc_name
  private_subnet_name  = var.private_subnet_name
  
  db_version                    = var.db_version
  db_tier                      = var.db_tier
  db_disk_type                 = var.db_disk_type
  db_disk_size                 = var.db_disk_size
  db_disk_autoresize_limit     = var.db_disk_autoresize_limit
  db_name                      = var.db_name
  db_username                  = var.db_username
  db_password                  = var.db_password
  
  availability_type            = var.availability_type
  deletion_protection          = var.deletion_protection
  backup_enabled               = var.backup_enabled
  point_in_time_recovery       = var.point_in_time_recovery
  
  db_backup_start_time         = var.db_backup_start_time
  db_backup_retention_count    = var.db_backup_retention_count
  db_transaction_log_retention_days = var.db_transaction_log_retention_days
  db_maintenance_day           = var.db_maintenance_day
  db_maintenance_hour          = var.db_maintenance_hour
  
  database_flags               = var.database_flags
  insights_enabled             = var.insights_enabled
  insights_query_string_length = var.insights_query_string_length
  insights_record_application_tags = var.insights_record_application_tags
  insights_record_client_address = var.insights_record_client_address
}

module "kubernetes" {
  count = var.deploy_to_gke ? 1 : 0
  
  source = "./modules/kubernetes"
  
  project_id            = var.project_id
  region               = var.region
  environment          = var.environment
  app_name             = var.app_name
  vpc_name             = var.vpc_name
  private_subnet_name  = var.private_subnet_name
  gke_service_account_email = var.gke_service_account_email
  
  gke_cluster_name     = var.gke_cluster_name
  gke_zone            = var.gke_zone
  gke_machine_type    = var.gke_machine_type
  gke_node_count      = var.gke_node_count
  gke_disk_size       = var.gke_disk_size
  gke_disk_type       = var.gke_disk_type
  gke_enable_autoscaling = var.gke_enable_autoscaling
  gke_min_node_count  = var.gke_min_node_count
  gke_max_node_count  = var.gke_max_node_count
}

module "app" {
  count = var.deploy_to_gke ? 1 : 0
  
  source = "./modules/app"
  
  cluster_endpoint        = module.kubernetes[0].cluster_endpoint
  cluster_token          = data.google_client_config.current[0].access_token
  cluster_ca_certificate = module.kubernetes[0].cluster_ca_certificate
  service_account_email  = module.kubernetes[0].service_account_email
  service_account_key    = module.kubernetes[0].service_account_key
  
  app_name      = var.app_name
  environment   = var.environment
  project_id    = var.project_id
  app_version   = var.app_version
  image_repository = var.image_repository
  image_tag     = var.image_tag
  replica_count = var.replica_count
  log_level     = var.log_level
  
  helm_repository   = var.helm_repository
  helm_chart_name   = var.helm_chart_name
  helm_chart_version = var.helm_chart_version
  helm_values_path  = var.helm_values_path
  
  db_host     = module.database[0].cloud_sql_private_ip
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  resource_limits_cpu    = var.resource_limits_cpu
  resource_limits_memory = var.resource_limits_memory
  resource_requests_cpu  = var.resource_requests_cpu
  resource_requests_memory = var.resource_requests_memory
  
  service_type = var.service_type
  
  enable_ingress     = var.enable_ingress
  ingress_class      = var.ingress_class
  ingress_host       = var.ingress_host
  enable_tls         = var.enable_tls
  cert_manager_issuer = var.cert_manager_issuer
  
  enable_autoscaling = var.enable_autoscaling
  hpa_min_replicas   = var.hpa_min_replicas
  hpa_max_replicas   = var.hpa_max_replicas
  hpa_cpu_target     = var.hpa_cpu_target
  hpa_memory_target  = var.hpa_memory_target
  
  use_private_registry = var.use_private_registry
}

resource "google_secret_manager_secret_iam_binding" "db_credentials_access" {
  count = var.deploy_to_gke ? 1 : 0
  
  secret_id = module.database[0].secret_manager_secret_id
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${var.gke_service_account_email}",
  ]
}
