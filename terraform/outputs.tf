output "cloud_sql_instance_name" {
  description = "Cloud SQL instance"
  value       = var.deploy_to_gke ? google_sql_database_instance.app_db[0].name : ""
}

output "cloud_sql_connection_name" {
  description = "Connection name of the cloud SQL instance"
  value       = var.deploy_to_gke ? google_sql_database_instance.app_db[0].connection_name : ""
}

output "cloud_sql_private_ip" {
  description = "Private IPaddress of the Cloud SQL instance"
  value       = var.deploy_to_gke ? google_sql_database_instance.app_db[0].private_ip_address : ""
}

output "database_name" {
  description = "database name"
  value       = var.deploy_to_gke ? google_sql_database.app_db[0].name : ""
}

output "database_username" {
  description = "Database username"
  value       = var.deploy_to_gke ? google_sql_user.app_user[0].name : ""
}

output "secret_manager_secret_id" {
  description = "Secret ID for database credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}

output "secret_manager_secret_name" {
  description = "Secret name for database credentials"
  value       = google_secret_manager_secret.db_credentials.name
}