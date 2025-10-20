provider "kubernetes" {
  host                   = var.cluster_endpoint
  token                  = var.cluster_token
  cluster_ca_certificate = var.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    token                  = var.cluster_token
    cluster_ca_certificate = var.cluster_ca_certificate
  }
}

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

resource "kubernetes_secret" "db_credentials" {
  metadata {
    name      = "${var.app_name}-${var.environment}-db-credentials"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  data = {
    username = var.db_username
    password = var.db_password
    host     = var.db_host
    port     = "5432"
    database = var.db_name
  }

  type = "Opaque"
}

resource "kubernetes_secret" "registry_secret" {
  count = var.use_private_registry ? 1 : 0

  metadata {
    name      = "registry-secret"
    namespace = kubernetes_namespace.app_namespace.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "gcr.io" = {
          auth = base64encode("_json_key:${base64decode(var.service_account_key)}")
        }
      }
    })
  }
}

resource "helm_release" "app" {
  name       = var.app_name
  repository = var.helm_repository
  chart      = var.helm_chart_name
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.app_namespace.metadata[0].name

  values = [
    file("${var.helm_values_path}")
  ]

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account"
    value = var.service_account_email
  }

  set {
    name  = "database.external.secretName"
    value = kubernetes_secret.db_credentials.metadata[0].name
  }

  set {
    name  = "secretManager.secretName"
    value = kubernetes_secret.db_credentials.metadata[0].name
  }

  set {
    name  = "secretManager.projectId"
    value = var.project_id
  }

  dynamic "set" {
    for_each = var.use_private_registry ? [1] : []
    content {
      name  = "imagePullSecrets[0].name"
      value = kubernetes_secret.registry_secret[0].metadata[0].name
    }
  }

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  create_namespace = false

  depends_on = [
    kubernetes_namespace.app_namespace,
    kubernetes_secret.db_credentials
  ]
}
