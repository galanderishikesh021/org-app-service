#!/bin/bash

# Plan Stage Script

set -e

ENVIRONMENT=$1
PROJECT_ID=$PROJECT_ID
GKE_CLUSTER=$GKE_CLUSTER
GKE_ZONE=$GKE_ZONE
TERRAFORM_VERSION=$TERRAFORM_VERSION
PLAN_FILE=$PLAN_FILE

echo "Starting Terraform plan for environment: $ENVIRONMENT"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

authenticate_gcp() {
    echo "Authenticating with Google Cloud..."
    
    if [[ -n "$GCP_SA_KEY" ]]; then
        echo "Using service account key..."
        echo "$GCP_SA_KEY" | base64 -d > /tmp/gcp-key.json
        export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp-key.json
        gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
    elif command_exists gcloud; then
        echo "Using existing gcloud authentication..."
        gcloud auth list
    else
        echo "No GCP authentication found. Please:"
        exit 1
    fi
    
    gcloud config set project "$PROJECT_ID"
    echo "GCP authentication completed"
}

setup_cloud_sdk() {
    echo "Setting up Cloud SDK..."
    
    if ! command_exists gcloud; then
        echo "gcloud CLI not found. Please install Google Cloud SDK"
        exit 1
    fi
    
    echo "Cloud SDK setup completed"
}

get_gke_credentials() {
    echo "Getting GKE credentials..."
    
    gcloud container clusters get-credentials "$GKE_CLUSTER" \
        --zone "$GKE_ZONE" \
        --project "$PROJECT_ID"
    
    echo "GKE credentials obtained"
}

setup_terraform() {
    echo "Setting up Terraform..."
    
    if ! command_exists terraform; then
        echo "Terraform not found. Please install Terraform $TERRAFORM_VERSION"
        exit 1
    fi
    
    TERRAFORM_CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version')
    echo "Current Terraform version: $TERRAFORM_CURRENT_VERSION\nTerraform setup completed"
}

terraform_init() {
    echo "Initializing Terraform..."
    cd terraform
    terraform init
    echo "Terraform initialized"
}

terraform_plan() {
    echo "Running Terraform plan..."
    cd terraform
    
    TFVARS_FILE="../environment/$ENVIRONMENT/$ENVIRONMENT-terraform.tfvars"
    if [[ ! -f "$TFVARS_FILE" ]]; then
        echo "Terraform variables file not found: $TFVARS_FILE"
        exit 1
    fi
    
    echo "Using variables file: $TFVARS_FILE"
    
    terraform plan \
        -var-file="$TFVARS_FILE" \
        -out="$PLAN_FILE" \
        -detailed-exitcode
    
    PLAN_EXIT_CODE=$?
    
    case $PLAN_EXIT_CODE in
        0)
            echo "No changes needed"
            ;;
        1)
            echo "Terraform plan failed"
            exit 1
            ;;
        2)
            echo "Changes detected and plan created"
            ;;
        *)
            echo "Unexpected exit code: $PLAN_EXIT_CODE"
            exit 1
            ;;
    esac
    
    echo "Terraform plan completed successfully"
}

save_plan_file() {
    echo "Saving Terraform plan file..."
    
    cd terraform
    
    if [[ -f "$PLAN_FILE" ]]; then
        mkdir -p ../artifacts
        
        cp "$PLAN_FILE" "../artifacts/terraform-plan-$ENVIRONMENT"
        echo "Plan file saved to: artifacts/terraform-plan-$ENVIRONMENT"
        ls -la "../artifacts/terraform-plan-$ENVIRONMENT"
    else
        echo "Plan file not found: $PLAN_FILE"
        exit 1
    fi
}

show_plan_summary() {
    echo "Terraform Plan Summary:"
    echo "=========================="
    
    cd terraform
    
    if [[ -f "$PLAN_FILE" ]]; then
        terraform show -no-color "$PLAN_FILE" | head -20
        echo "..."
        echo "Full plan details saved in: artifacts/terraform-plan-$ENVIRONMENT"
    fi
}

setup_environment() {
    echo "Setting up environment..."
    
    mkdir -p logs
    mkdir -p artifacts
    
    echo "Environment: $ENVIRONMENT"
    echo "Project ID: $PROJECT_ID"
    echo "GKE Cluster: $GKE_CLUSTER"
    echo "GKE Zone: $GKE_ZONE"
    echo "Terraform Version: $TERRAFORM_VERSION"
    echo "Plan File: $PLAN_FILE"
}

cleanup() {
    echo "Cleaning up..."
    if [[ -f "/tmp/gcp-key.json" ]]; then
        rm -f /tmp/gcp-key.json
    fi
    
    echo "Cleanup completed"
}

error_handler() {
    echo "Plan failed at line $1"
    cleanup
    exit 1
}

trap 'error_handler $LINENO' ERR

main() {
    echo "=========================================="
    echo "PLAN STAGE - $ENVIRONMENT  STARTED    "
    echo "=========================================="
    
    setup_environment
    authenticate_gcp
    setup_cloud_sdk
    get_gke_credentials
    setup_terraform
    terraform_init
    terraform_plan
    save_plan_file
    show_plan_summary
    cleanup
    
    echo "=========================================="
    echo "PLAN COMPLETED SUCCESSFULLY"
    echo "=========================================="
}

main "$@"
