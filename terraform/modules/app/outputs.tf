# App Module Outputs - Helm Deployment

output "namespace_name" {
  description = "Name of the Kubernetes namespace"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.app.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release"
  value       = helm_release.app.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.app.status
}

output "helm_release_version" {
  description = "Version of the Helm release"
  value       = helm_release.app.version
}

output "secret_name" {
  description = "Name of the database credentials secret"
  value       = kubernetes_secret.db_credentials.metadata[0].name
}

output "registry_secret_name" {
  description = "Name of the registry secret"
  value       = var.use_private_registry ? kubernetes_secret.registry_secret[0].metadata[0].name : ""
}