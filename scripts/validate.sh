#!/bin/bash

# Validate Stage Script

set -e 

ENVIRONMENT=$1
PROJECT_ID=$PROJECT_ID
SERVICE=$SERVICE
PYTHON_VERSION=$PYTHON_VERSION
TERRAFORM_VERSION=$TERRAFORM_VERSION

echo "Starting validation for environment: $ENVIRONMENT"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_python_deps() {
    echo "Installing Python dependencies..."
    if command_exists python3; then
        python3 -m pip install --upgrade pip
        pip install -r requirements.txt
    else
        echo "Python3 not found. Please install Python $PYTHON_VERSION"
        exit 1
    fi
}

validate_terraform() {
    echo "Validating Terraform..."
    
    if ! command_exists terraform; then
        echo "Terraform not found. Please install Terraform $TERRAFORM_VERSION"
        exit 1
    fi
    
    cd terraform
    
    echo "Initializing Terraform..."
    terraform init
    
    echo "Validating Terraform configuration..."
    terraform validate
    
    echo "Checking Terraform formatting..."
    terraform fmt -check
    
    cd ..
    echo "Terraform validation completed successfully"
}

setup_environment() {
    echo "Setting up environment..."
    
    mkdir -p logs
    mkdir -p artifacts
    
    echo "Environment: $ENVIRONMENT"
    echo "Project ID: $PROJECT_ID"
    echo "Service: $SERVICE"
}

main() {
    echo "=========================================="
    echo "VALIDATION STAGE - $ENVIRONMENT STARTED"
    echo "=========================================="
    
    setup_environment
    install_python_deps
    validate_terraform
    
    echo "=========================================="
    echo "VALIDATION COMPLETED SUCCESSFULLY"
    echo "=========================================="
}

main "$@"
