# Development Environment Configuration
project_id = "crucial-study-475405-e4"
region = "us-central1"
environment = "dev"
app_name = "app"
deploy_to_gke = true

# VPC Configuration
vpc_name = "app-dev-vpc"
private_subnet_name = "app-dev-subnet"
gke_service_account_email = "app-dev@crucial-study-475405-e4.iam.gserviceaccount.com"

# Database Configuration
db_version = "POSTGRES_15"
db_tier = "db-f1-micro"
db_disk_type = "PD_SSD"
db_disk_size = 20
db_disk_autoresize_limit = 50
db_name = "appdb"
db_username = "appuser"
db_password = "dev-password-change-me"

# Backup Configuration
db_backup_start_time = "03:00"
db_backup_retention_count = 3
db_transaction_log_retention_days = 3
db_maintenance_day = 1
db_maintenance_hour = 4
