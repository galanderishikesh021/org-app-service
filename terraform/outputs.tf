output "cloud_sql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = var.deploy_to_gke ? module.database[0].cloud_sql_instance_name : ""
}

output "cloud_sql_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = var.deploy_to_gke ? module.database[0].cloud_sql_connection_name : ""
}

output "cloud_sql_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = var.deploy_to_gke ? module.database[0].cloud_sql_private_ip : ""
}

output "database_name" {
  description = "Name of the database"
  value       = var.deploy_to_gke ? module.database[0].database_name : ""
}

output "database_username" {
  description = "Database username"
  value       = var.deploy_to_gke ? module.database[0].database_username : ""
}

output "secret_manager_secret_id" {
  description = "Secret Manager secret ID for database credentials"
  value       = var.deploy_to_gke ? module.database[0].secret_manager_secret_id : ""
}

output "secret_manager_secret_name" {
  description = "Secret Manager secret name for database credentials"
  value       = var.deploy_to_gke ? module.database[0].secret_manager_secret_name : ""
}

# Kubernetes Outputs
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.deploy_to_gke ? module.kubernetes[0].cluster_name : ""
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = var.deploy_to_gke ? module.kubernetes[0].cluster_endpoint : ""
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = var.deploy_to_gke ? module.kubernetes[0].cluster_location : ""
}

output "service_account_email" {
  description = "Email of the application service account"
  value       = var.deploy_to_gke ? module.kubernetes[0].service_account_email : ""
}

output "namespace_name" {
  description = "Name of the Kubernetes namespace"
  value       = var.deploy_to_gke ? module.app[0].namespace_name : ""
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = var.deploy_to_gke ? module.app[0].helm_release_name : ""
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = var.deploy_to_gke ? module.app[0].helm_release_status : ""
}

output "helm_release_version" {
  description = "Version of the Helm release"
  value       = var.deploy_to_gke ? module.app[0].helm_release_version : ""
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = var.deploy_to_gke ? module.app[0].secret_name : ""
}

output "registry_secret_name" {
  description = "Name of the registry secret"
  value       = var.deploy_to_gke ? module.app[0].registry_secret_name : ""
}
