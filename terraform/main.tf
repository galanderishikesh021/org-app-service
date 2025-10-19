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

data "google_compute_network" "existing" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "private" {
  name   = var.private_subnet_name
  region = var.region
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.app_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.existing.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.existing.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "app_db" {
  count = var.deploy_to_gke ? 1 : 0
  name             = "${var.app_name}-${var.environment}-db"
  database_version = var.db_version
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = var.db_tier
    availability_type           = var.environment == "prod" ? "REGIONAL" : "ZONAL"
    disk_type                   = var.db_disk_type
    disk_size                   = var.db_disk_size
    disk_autoresize             = true
    disk_autoresize_limit       = var.db_disk_autoresize_limit
    deletion_protection_enabled = var.environment == "prod" ? true : false

    backup_configuration {
      enabled                        = true
      start_time                     = var.db_backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = var.environment == "prod" ? true : false
      transaction_log_retention_days = var.db_transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.db_backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.existing.id
      enable_private_path_for_google_cloud_services = true
    }

    maintenance_window {
      day          = var.db_maintenance_day
      hour         = var.db_maintenance_hour
      update_track = "stable"
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "1000"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = var.environment == "prod" ? true : false

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
    ]
  }
}

resource "google_sql_database" "app_db" {
  count    = var.deploy_to_gke ? 1 : 0
  name     = var.db_name
  instance = google_sql_database_instance.app_db[0].name
}

resource "google_sql_user" "app_user" {
  count    = var.deploy_to_gke ? 1 : 0
  name     = var.db_username
  instance = google_sql_database_instance.app_db[0].name
  password = var.db_password
}

resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${var.app_name}-${var.environment}-db-credentials"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    application = var.app_name
  }
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.deploy_to_gke ? google_sql_database_instance.app_db[0].private_ip_address : ""
    port     = "5432"
    database = var.db_name
    connection_name = var.deploy_to_gke ? google_sql_database_instance.app_db[0].connection_name : ""
  })
}

resource "google_service_account" "app_service_account" {
  count        = var.deploy_to_gke ? 1 : 0
  account_id   = "${var.app_name}-${var.environment}-sa"
  display_name = "Application Service Account for ${var.app_name} ${var.environment}"
  description  = "Service account for ${var.app_name} application in ${var.environment} environment"
}

resource "google_service_account_key" "registry_key" {
  count              = var.deploy_to_gke ? 1 : 0
  service_account_id = google_service_account.app_service_account[0].name
}

resource "google_secret_manager_secret_iam_binding" "db_credentials_access" {
  secret_id = google_secret_manager_secret.db_credentials.secret_id
  role      = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${var.gke_service_account_email}",
  ]
}

resource "google_container_cluster" "primary" {
  count    = var.deploy_to_gke ? 1 : 0
  name     = var.gke_cluster_name != "" ? var.gke_cluster_name : "${var.app_name}-${var.environment}-cluster"
  location = var.gke_zone
  
  remove_default_node_pool = true
  initial_node_count       = 1
  
  network    = data.google_compute_network.existing.id
  subnetwork = data.google_compute_subnetwork.private.id
  
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  }
  
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  
  network_policy {
    enabled = true
  }
  
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
  
  enable_shielded_nodes = true
  
  confidential_nodes {
    enabled = false
  }
}

resource "google_container_node_pool" "primary_nodes" {
  count      = var.deploy_to_gke ? 1 : 0
  name       = "${var.app_name}-${var.environment}-node-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary[0].name
  node_count = var.gke_node_count
  
  node_config {
    preemptible  = false
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size
    disk_type    = var.gke_disk_type
    
    service_account = var.gke_service_account_email
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
  
  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
    enabled        = var.gke_enable_autoscaling
  }
  
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}