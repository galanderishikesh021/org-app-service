# Kubernetes Provider Configuration
# This will work with both Minikube and GKE
provider "kubernetes" {
  # For GKE, use the cluster endpoint
  # For Minikube, use the local context
  config_path = var.kubernetes_config_path != "" ? var.kubernetes_config_path : null
  
  # GKE cluster configuration (when not using local config)
  host                   = var.deploy_to_gke ? "https://${google_container_cluster.primary[0].endpoint}" : null
  token                  = var.deploy_to_gke ? data.google_client_config.current[0].access_token : null
  cluster_ca_certificate = var.deploy_to_gke ? base64decode(google_container_cluster.primary[0].master_auth[0].cluster_ca_certificate) : null
}

# Helm Provider Configuration
provider "helm" {
  kubernetes {
    # For GKE, use the cluster endpoint
    # For Minikube, use the local context
    config_path = var.kubernetes_config_path != "" ? var.kubernetes_config_path : null
    
    # GKE cluster configuration (when not using local config)
    host                   = var.deploy_to_gke ? "https://${google_container_cluster.primary[0].endpoint}" : null
    token                  = var.deploy_to_gke ? data.google_client_config.current[0].access_token : null
    cluster_ca_certificate = var.deploy_to_gke ? base64decode(google_container_cluster.primary[0].master_auth[0].cluster_ca_certificate) : null
  }
}

# Data source for current GCP client configuration
data "google_client_config" "current" {
  count = var.deploy_to_gke ? 1 : 0
}

# Kubernetes Namespace
resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.environment
    labels = {
      name        = var.environment
      environment = var.environment
      application = var.app_name
    }
  }
}

# Kubernetes Service Account
resource "kubernetes_service_account" "app_service_account" {
  metadata {
    name      = "${var.app_name}-sa"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = var.deploy_to_gke ? {
      "iam.gke.io/gcp-service-account" = google_service_account.app_service_account[0].email
    } : {}
  }
}

# Kubernetes Secret for database credentials
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "${var.app_name}-db-credentials"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    username = var.db_username
    password = var.db_password
    host     = var.deploy_to_gke ? google_sql_database_instance.app_db[0].private_ip_address : var.db_host
    port     = "5432"
    database = var.db_name
  }

  type = "Opaque"
}

# Kubernetes ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    ENVIRONMENT = var.environment
    LOG_LEVEL   = var.log_level
    PORT        = "8080"
    DB_HOST     = var.deploy_to_gke ? google_sql_database_instance.app_db[0].private_ip_address : var.db_host
    DB_PORT     = "5432"
    DB_NAME     = var.db_name
    DB_USER     = var.db_username
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "app_deployment" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app     = var.app_name
      version = var.app_version
    }
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = var.app_version
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.app_service_account.metadata[0].name

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          fs_group        = 2000
        }

        container {
          name  = var.app_name
          image = "${var.image_repository}:${var.image_tag}"

          port {
            container_port = 8080
            name          = "http"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_credentials.metadata[0].name
                key  = "password"
              }
            }
          }

          resources {
            limits = {
              cpu    = var.resource_limits_cpu
              memory = var.resource_limits_memory
            }
            requests = {
              cpu    = var.resource_requests_cpu
              memory = var.resource_requests_memory
            }
          }

          liveness_probe {
            http_get {
              path = "/api/live"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/api/ready"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1000
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        # For Minikube, use local image
        dynamic "image_pull_secrets" {
          for_each = var.deploy_to_gke ? [1] : []
          content {
            name = kubernetes_secret.registry_secret[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Kubernetes Service
resource "kubernetes_service" "app_service" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Kubernetes Ingress
resource "kubernetes_ingress_v1" "app_ingress" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = var.ingress_class
      "cert-manager.io/cluster-issuer"             = var.cert_manager_issuer
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.ingress_host]
        secret_name = "${var.app_name}-tls"
      }
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.app_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  count = var.enable_autoscaling ? 1 : 0

  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app_deployment.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }
}

# Network Policy
resource "kubernetes_network_policy" "app_network_policy" {
  count = var.enable_network_policy ? 1 : 0

  metadata {
    name      = "${var.app_name}-network-policy"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = {
        app = var.app_name
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            name = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# Registry Secret for GKE (when using private registry)
resource "kubernetes_secret" "registry_secret" {
  count = var.deploy_to_gke ? 1 : 0

  metadata {
    name      = "registry-secret"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "gcr.io" = {
          auth = base64encode("_json_key:${base64decode(google_service_account_key.registry_key[0].private_key)}")
        }
      }
    })
  }
}
