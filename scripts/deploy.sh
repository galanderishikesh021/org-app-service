#!/bin/bash

# Main Deployment Script

set -e

ENVIRONMENT=$1
STAGES=$2
IMAGE_NAME=$3
IMAGE_TAG=$4
PROJECT_ID=$PROJECT_ID
GKE_CLUSTER=$GKE_CLUSTER
GKE_ZONE=$GKE_ZONE
REGISTRY=$REGISTRY
SERVICE=$SERVICE
AUTO_APPROVE=$AUTO_APPROVE
SKIP_STAGES=$SKIP_STAGES


echo -e "Starting deployment pipeline for environment: $ENVIRONMENT${NC}"

print_status() {
    local status=$1
    local message=$2
    case $status in
        "info")
            echo -e "$message${NC}"
            ;;
        "success")
            echo -e "$message${NC}"
            ;;
        "warning")
            echo -e "$message${NC}"
            ;;
        "error")
            echo -e "$message${NC}"
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_prerequisites() {
    print_status "info" "Checking prerequisites..."
    
    local missing_deps=()
    
    for cmd in docker gcloud kubectl terraform git; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_status "error" "Missing required dependencies: ${missing_deps[*]}"
        print_status "info" "Please install the missing dependencies and try again."
        exit 1
    fi
    
    if [[ ! -d "scripts" ]]; then
        print_status "error" "Scripts directory not found. Please run from project root."
        exit 1
    fi
    
    local required_scripts=("validate.sh" "build.sh" "plan.sh" "deploy.sh" "post-apply.sh")
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "scripts/$script" ]]; then
            print_status "error" "Required script not found: scripts/$script"
            exit 1
        fi
    done
    
    print_status "success" "Prerequisites check passed"
}

setup_environment() {
    print_status "info" "Setting up environment..."
    
    mkdir -p logs
    mkdir -p artifacts
    
    print_status "success" "Environment setup completed"
}

run_stage() {
    local stage=$1
    local script_path="scripts/$stage.sh"
    
    print_status "info" "Starting stage: $stage"
    echo "=========================================="
    
    if [[ "$SKIP_STAGES" == *"$stage"* ]]; then
        print_status "warning" "Skipping stage: $stage"
        return 0
    fi
    
    if [[ ! -f "$script_path" ]]; then
        print_status "error" "Stage script not found: $script_path"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
    fi
    
    local start_time=$(date +%s)
    local result=0
    
    case "$stage" in
        "build")
            if [[ -n "$IMAGE_NAME" && -n "$IMAGE_TAG" ]]; then
                "$script_path" "$ENVIRONMENT" "$IMAGE_NAME" "$IMAGE_TAG"
            else
                "$script_path" "$ENVIRONMENT"
            fi
            result=$?
            ;;
        *)
            "$script_path" "$ENVIRONMENT"
            result=$?
            ;;
    esac
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $result -eq 0 ]]; then
        print_status "success" "Stage '$stage' completed successfully in ${duration}s"
        return 0
    else
        print_status "error" "Stage '$stage' failed after ${duration}s"
        return 1
    fi
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-stages)
                SKIP_STAGES="$2"
                shift 2
                ;;
            --auto-approve)
                AUTO_APPROVE=true
                shift
                ;;
            *)
                if [[ -z "$ENVIRONMENT" ]]; then
                    ENVIRONMENT="$1"
                elif [[ "$STAGES" == "validate,build,plan,deploy,post-apply" ]]; then
                    STAGES="$1"
                fi
                shift
                ;;
        esac
    done
}

validate_environment() {
    case "$ENVIRONMENT" in
        "dev"|"staging"|"prod")
            print_status "success" "Valid environment: $ENVIRONMENT"
            ;;
        *)
            print_status "error" "Invalid environment: $ENVIRONMENT"
            print_status "info" "Valid environments: dev, staging, prod"
            exit 1
            ;;
    esac
}

show_summary() {
    echo ""
    echo "=========================================="
    print_status "success" "DEPLOYMENT PIPELINE COMPLETED"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Stages run: $STAGES"
    echo "Commit SHA: $GITHUB_SHA"
    echo "Timestamp: $(date)"
    echo "=========================================="
}

error_handler() {
    print_status "error" "Deployment pipeline failed at line $1"
    echo ""
    echo "=========================================="
    print_status "error" "DEPLOYMENT PIPELINE FAILED"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Failed at: $(date)"
    echo "Check logs for more details"
    echo "=========================================="
    exit 1
}

trap 'error_handler $LINENO' ERR

main() {
    echo "=========================================="
    echo -e " DEPLOYMENT PIPELINE - $ENVIRONMENT${NC}"
    echo "=========================================="
    
    parse_arguments "$@"
    
    validate_environment
    
    check_prerequisites
    
    setup_environment
    
    print_status "info" "Configuration:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Stages: $STAGES"
    echo "  Image Name: ${IMAGE_NAME:-"<default>"}"
    echo "  Image Tag: ${IMAGE_TAG:-"<default>"}"
    echo "  Project ID: $PROJECT_ID"
    echo "  GKE Cluster: $GKE_CLUSTER"
    echo "  GKE Zone: $GKE_ZONE"
    echo "  Registry: $REGISTRY"
    echo "  Service: $SERVICE"
    echo "  Auto Approve: $AUTO_APPROVE"
    echo "  Skip Stages: $SKIP_STAGES"
    echo ""
    
    IFS=',' read -ra STAGE_ARRAY <<< "$STAGES"
    for stage in "${STAGE_ARRAY[@]}"; do
        stage=$(echo "$stage" | xargs)
        if ! run_stage "$stage"; then
            print_status "error" "Pipeline failed at stage: $stage"
            exit 1
        fi
        echo ""
    done
    
    show_summary
}

main "$@"
