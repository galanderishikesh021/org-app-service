# Kubernetes and Application Deployment Variables

variable "deploy_to_gke" {
  description = "Deploy to GKE"
  type        = bool
  default     = true
}

variable "kubernetes_config_path" {
  description = "Path to Kubernetes config file"
  type        = string
  default     = ""
}

# Application Configuration
variable "app_version" {
  description = "Application version"
  type        = string
  default     = "1.0.0"
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
  default     = "gcr.io/app-web/app"
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "replica_count" {
  description = "Number of application replicas"
  type        = number
  default     = 2
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error."
  }
}

# Database Configuration for Minikube
variable "db_host" {
  description = "Database host (for Minikube deployment)"
  type        = string
  default     = "localhost"
}

# Resource Configuration
variable "resource_limits_cpu" {
  description = "CPU limit for application containers"
  type        = string
  default     = "500m"
}

variable "resource_limits_memory" {
  description = "Memory limit for application containers"
  type        = string
  default     = "512Mi"
}

variable "resource_requests_cpu" {
  description = "CPU request for application containers"
  type        = string
  default     = "250m"
}

variable "resource_requests_memory" {
  description = "Memory request for application containers"
  type        = string
  default     = "256Mi"
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable Kubernetes ingress"
  type        = bool
  default     = true
}

variable "ingress_class" {
  description = "Ingress class"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress host"
  type        = string
  default     = "app.inc.com"
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = true
}

variable "cert_manager_issuer" {
  description = "Cert-manager cluster issuer"
  type        = string
  default     = "letsencrypt-prod"
}

# Autoscaling Configuration
variable "enable_autoscaling" {
  description = "Enable horizontal pod autoscaling"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "hpa_cpu_target" {
  description = "CPU target percentage"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "Memory target percentage"
  type        = number
  default     = 80
}

variable "enable_network_policy" {
  description = "Enable network policies"
  type        = bool
  default     = true
}

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
  description = "?achine type"
  type        = string
  default     = "e2-standard-2"
}

variable "gke_node_count" {
  description = "Number of  nodes"
  type        = number
  default     = 3
}

variable "gke_disk_size" {
  description = "Node disk size"
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
