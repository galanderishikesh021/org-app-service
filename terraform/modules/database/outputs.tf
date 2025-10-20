# Database Module Outputs

output "cloud_sql_instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.app_db.name
}

output "cloud_sql_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.app_db.connection_name
}

output "cloud_sql_private_ip" {
  description = "Private IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.app_db.private_ip_address
}

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.app_db.name
}

output "database_username" {
  description = "Database username"
  value       = google_sql_user.app_user.name
}

output "secret_manager_secret_id" {
  description = "Secret Manager secret ID for database credentials"
  value       = google_secret_manager_secret.db_credentials.secret_id
}

output "secret_manager_secret_name" {
  description = "Secret Manager secret name for database credentials"
  value       = google_secret_manager_secret.db_credentials.name
}
