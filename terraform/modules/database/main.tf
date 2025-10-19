
data "google_compute_network" "existing" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "private" {
  name   = var.private_subnet_name
  region = var.region
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.app_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.existing.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.existing.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "app_db" {
  name             = "${var.app_name}-${var.environment}-db"
  database_version = var.db_version
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier                        = var.db_tier
    availability_type           = var.availability_type
    disk_type                   = var.db_disk_type
    disk_size                   = var.db_disk_size
    disk_autoresize             = true
    disk_autoresize_limit       = var.db_disk_autoresize_limit
    deletion_protection_enabled = var.deletion_protection

    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.db_backup_start_time
      location                       = var.region
      point_in_time_recovery_enabled = var.point_in_time_recovery
      transaction_log_retention_days = var.db_transaction_log_retention_days
      backup_retention_settings {
        retained_backups = var.db_backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = data.google_compute_network.existing.id
      enable_private_path_for_google_cloud_services = true
    }

    maintenance_window {
      day          = var.db_maintenance_day
      hour         = var.db_maintenance_hour
      update_track = "stable"
    }

    # Environment-specific database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    insights_config {
      query_insights_enabled  = var.insights_enabled
      query_string_length     = var.insights_query_string_length
      record_application_tags = var.insights_record_application_tags
      record_client_address   = var.insights_record_client_address
    }
  }

  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
    ]
  }
}

resource "google_sql_database" "app_db" {
  name     = var.db_name
  instance = google_sql_database_instance.app_db.name
}

resource "google_sql_user" "app_user" {
  name     = var.db_username
  instance = google_sql_database_instance.app_db.name
  password = var.db_password
}

resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${var.app_name}-${var.environment}-db-credentials"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    application = var.app_name
    managed-by  = "terraform"
  }
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = google_sql_database_instance.app_db.private_ip_address
    port     = "5432"
    database = var.db_name
    connection_name = google_sql_database_instance.app_db.connection_name
  })
}
