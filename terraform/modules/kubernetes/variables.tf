# Kubernetes Module Variables

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
}

variable "gke_service_account_email" {
  description = "GKE service account email for Workload Identity"
  type        = string
}

# GKE-specific Configuration
variable "gke_cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = ""
}

variable "gke_zone" {
  description = "GKE zone"
  type        = string
  default     = "us-central1-a"
}

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-2"
}

variable "gke_node_count" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_disk_size" {
  description = "GKE node disk size in GB"
  type        = number
  default     = 50
}

variable "gke_disk_type" {
  description = "GKE node disk type"
  type        = string
  default     = "pd-ssd"
}

variable "gke_enable_autoscaling" {
  description = "Enable GKE cluster autoscaling"
  type        = bool
  default     = true
}

variable "gke_min_node_count" {
  description = "Minimum number of GKE nodes"
  type        = number
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum number of GKE nodes"
  type        = number
  default     = 10
}

variable "master_authorized_networks" {
  description = "CIDR blocks authorized to access the GKE master"
  type        = string
  default     = "10.0.0.0/8"
}

variable "cost_center" {
  description = "Cost center for resource tagging"
  type        = string
  default     = "engineering"
}
