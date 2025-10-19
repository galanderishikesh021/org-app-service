# Staging Environment Configuration
project_id = "crucial-study-475405-e4"
region = "us-central1"
environment = "staging"
app_name = "app"
deploy_to_gke = true

# VPC Configuration
vpc_name = "app-staging-vpc"
private_subnet_name = "app-staging-subnet"
gke_service_account_email = "app-stage@crucial-study-475405-e4.iam.gserviceaccount.com"

# Database Configuration
db_version = "POSTGRES_15"
db_tier = "db-g1-small"
db_disk_type = "PD_SSD"
db_disk_size = 50
db_disk_autoresize_limit = 100
db_name = "appdb"
db_username = "appuser"
db_password = "staging-password-change-me"

# Backup Configuration
db_backup_start_time = "03:00"
db_backup_retention_count = 7
db_transaction_log_retention_days = 7
db_maintenance_day = 1
db_maintenance_hour = 4
