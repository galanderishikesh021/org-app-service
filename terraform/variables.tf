# General Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "app"
}

# VPC Configuration
variable "vpc_name" {
  description = "Name of the existing VPC"
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
}

variable "gke_service_account_email" {
  description = "GKE service account email"
  type        = string
}

variable "db_version" {
  description = "Cloud SQL database version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_type" {
  description = "cloud SQL disk type"
  type        = string
  default     = "PD_SSD"
}

variable "db_disk_size" {
  description = "cloud SQL disk size"
  type        = number
  default     = 20
}

variable "db_disk_autoresize_limit" {
  description = "Maximum disk size for auto-resize in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_backup_start_time" {
  description = "Backup start time"
  type        = string
  default     = "03:00"
}

variable "db_backup_retention_count" {
  description = "Number of backups to retain"
  type        = number
  default     = 7
}

variable "db_transaction_log_retention_days" {
  description = "Transaction log retention in days"
  type        = number
  default     = 7
}

variable "db_maintenance_day" {
  description = "Maintenance day"
  type        = number
  default     = 1
}

variable "db_maintenance_hour" {
  description = "Maintenance hour (0-23)"
  type        = number
  default     = 4
}

# Environment-specific database settings
variable "availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = false
}

variable "database_flags" {
  description = "Database flags for environment-specific configuration"
  type = list(object({
    name  = string
    value = string
  }))
  default = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}

variable "insights_enabled" {
  description = "Enable query insights"
  type        = bool
  default     = true
}

variable "insights_query_string_length" {
  description = "Query string length for insights"
  type        = number
  default     = 1024
}

variable "insights_record_application_tags" {
  description = "Record application tags in insights"
  type        = bool
  default     = true
}

variable "insights_record_client_address" {
  description = "Record client address in insights"
  type        = bool
  default     = true
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "use_private_registry" {
  description = "Use private container registry"
  type        = bool
  default     = true
}

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

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}
