# Database Module Variables - Environment-Aware

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

# Database Configuration
variable "db_version" {
  description = "Cloud SQL database version"
  type        = string
  default     = "POSTGRES_15"
}

variable "db_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_disk_type" {
  description = "Cloud SQL disk type"
  type        = string
  default     = "PD_SSD"
}

variable "db_disk_size" {
  description = "Cloud SQL disk size in GB"
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

# Environment-specific configurations
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

# Backup Configuration
variable "db_backup_start_time" {
  description = "Backup start time (HH:MM format)"
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
  description = "Maintenance day (1-7, Sunday=1)"
  type        = number
  default     = 1
}

variable "db_maintenance_hour" {
  description = "Maintenance hour (0-23)"
  type        = number
  default     = 4
}

# Database flags for environment-specific tuning
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

# Insights configuration
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