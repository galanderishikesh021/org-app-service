# Kubernetes Module Outputs

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "service_account_email" {
  description = "Email of the application service account"
  value       = google_service_account.app_service_account.email
}

output "service_account_key" {
  description = "Service account key for registry access"
  value       = google_service_account_key.registry_key.private_key
  sensitive   = true
}
