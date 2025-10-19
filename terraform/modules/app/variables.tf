variable "cluster_endpoint" {
  description = "GKE cluster endpoint"
  type        = string
}

variable "cluster_token" {
  description = "GKE cluster access token"
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  type        = string
}

variable "service_account_email" {
  description = "GCP service account email for Workload Identity"
  type        = string
}

variable "service_account_key" {
  description = "GCP service account key for registry access"
  type        = string
  sensitive   = true
}

# Application Configuration
variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# Helm Configuration
variable "helm_repository" {
  description = "Helm repository URL"
  type        = string
  default     = ""
}

variable "helm_chart_name" {
  description = "Helm chart name"
  type        = string
  default     = "app"
}

variable "helm_chart_version" {
  description = "Helm chart version"
  type        = string
  default     = ""
}

variable "helm_values_path" {
  description = "Path to environment-specific Helm values file"
  type        = string
}

# Dynamic values that need to be overridden
variable "image_repository" {
  description = "Container image repository"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
}

# Database Configuration
variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# Registry Configuration
variable "use_private_registry" {
  description = "Use private container registry"
  type        = bool
  default     = true
}