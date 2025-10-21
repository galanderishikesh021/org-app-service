#!/bin/bash

# Terraform Apply Stage


set -e

ENVIRONMENT=$1
PROJECT_ID=$PROJECT_ID
GKE_CLUSTER=$GKE_CLUSTER
GKE_ZONE=$GKE_ZONE
AUTO_APPROVE=$AUTO_APPROVE

echo "Starting Terraform apply for environment: $ENVIRONMENT"
cd terraform
echo "Initializing Terraform..."
terraform init

echo "Applying Terraform plan..."
if [[ "$AUTO_APPROVE" == "true" ]]; then
    terraform apply -auto-approve -var-file="environment/$ENVIRONMENT/${ENVIRONMENT}-terraform.tfvars"
else
    terraform apply -var-file="environment/$ENVIRONMENT/${ENVIRONMENT}-terraform.tfvars"
fi

echo "Terraform apply completed successfully"
