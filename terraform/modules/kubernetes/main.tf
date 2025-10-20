data "google_compute_network" "existing" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "private" {
  name   = var.private_subnet_name
  region = var.region
}

data "google_client_config" "current" {}

resource "google_container_cluster" "primary" {
  name     = var.gke_cluster_name != "" ? var.gke_cluster_name : "${var.app_name}-${var.environment}-cluster"
  location = var.gke_zone
  
  resource_labels = {
    environment = var.environment
    application = var.app_name
    managed-by  = "terraform"
    cost-center = var.cost_center
  }
  
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
      cidr_block   = var.master_authorized_networks
      display_name = "Authorized Networks"
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
  name       = "${var.app_name}-${var.environment}-node-pool"
  location   = var.gke_zone
  cluster    = google_container_cluster.primary.name
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

resource "google_service_account" "app_service_account" {
  account_id   = "${var.app_name}-${var.environment}-sa"
  display_name = "Application Service Account for ${var.app_name} ${var.environment}"
  description  = "Service account for ${var.app_name} application in ${var.environment} environment"
}

resource "google_service_account_key" "registry_key" {
  service_account_id = google_service_account.app_service_account.name
}
