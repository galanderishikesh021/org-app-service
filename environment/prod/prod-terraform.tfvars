# Production Environment Configuration
project_id = "crucial-study-475405-e4"
region = "us-central1"
environment = "prod"
app_name = "app"
deploy_to_gke = true

# VPC Configuration
vpc_name = "app-prod-vpc"
private_subnet_name = "app-prod-subnet"
gke_service_account_email = "app-prod@crucial-study-475405-e4.iam.gserviceaccount.com"

# Database Configuration
db_version = "POSTGRES_15"
db_tier = "db-standard-2"
db_disk_type = "PD_SSD"
db_disk_size = 100
db_disk_autoresize_limit = 200
db_name = "appdb"
db_username = "appuser"
db_password = "prod-password-change-me"

# Backup Configuration
db_backup_start_time = "02:00"
db_backup_retention_count = 30
db_transaction_log_retention_days = 30
db_maintenance_day = 7
db_maintenance_hour = 3


availability_type = "REGIONAL"
deletion_protection = true
backup_enabled = true
point_in_time_recovery = true

# Helm Configuration
helm_values_path = "environment/prod/prod-values.yaml"
