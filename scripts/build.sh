#!/bin/bash

# Build Stage Script

set -e 


ENVIRONMENT=$1
IMAGE_NAME=$IMAGE_NAME
IMAGE_TAG=$IMAGE_TAG
PROJECT_ID=$PROJECT_ID
GKE_CLUSTER=$GKE_CLUSTER
GKE_ZONE=$GKE_ZONE
REGISTRY=$REGISTRY
SERVICE=$SERVICE
GITHUB_SHA=$GITHUB_SHA
echo "Starting build for environment: $ENVIRONMENT"

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
        echo "No GCP authentication found."
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
    
    gcloud auth configure-docker
    echo "Cloud SDK setup completed"
}

build_docker_image() {
    echo "Building Docker image..."
    
    if ! command_exists docker; then
        echo "Docker not found. Please install Docker"
        exit 1
    fi
    
    if [[ -n "$IMAGE_NAME" ]]; then
        FULL_IMAGE_NAME="$IMAGE_NAME"
    else
        FULL_IMAGE_NAME="$REGISTRY/$PROJECT_ID/$SERVICE"
    fi
    
    if [[ -n "$IMAGE_TAG" ]]; then
        IMAGE_TAG_FULL="$FULL_IMAGE_NAME:$IMAGE_TAG"
        LATEST_TAG="$FULL_IMAGE_NAME:latest"
    else
        IMAGE_TAG_FULL="$FULL_IMAGE_NAME:$ENVIRONMENT-$GITHUB_SHA"
        LATEST_TAG="$FULL_IMAGE_NAME:$ENVIRONMENT-latest"
    fi
    
    echo "Building image: $IMAGE_TAG_FULL"
    docker build -t "$IMAGE_TAG_FULL" .
    docker tag "$IMAGE_TAG_FULL" "$LATEST_TAG"
    
    echo "$IMAGE_TAG_FULL" > artifacts/image-name.txt
    echo "$LATEST_TAG" > artifacts/image-latest.txt
    
    echo "Docker image built successfully\nImage: $IMAGE_TAG_FULL\nLatest: $LATEST_TAG"
}

push_docker_image() {
    echo "Pushing Docker image to registry..."
    
    if [[ -f "artifacts/image-name.txt" ]]; then
        IMAGE_TAG_FULL=$(cat artifacts/image-name.txt)
        LATEST_TAG=$(cat artifacts/image-latest.txt)
    else
        echo "Image name file not found. Run build_docker_image first."
        exit 1
    fi
    
    docker push "$IMAGE_TAG_FULL"
    docker push "$LATEST_TAG"
    
    echo "Docker image pushed successfully\nPushed: $IMAGE_TAG_FULL\nPushed: $LATEST_TAG"
}

verify_image() {
    echo "Verifying pushed image..."
    
    if [[ -f "artifacts/image-name.txt" ]]; then
        IMAGE_TAG_FULL=$(cat artifacts/image-name.txt)
    else
        echo "Image name file not found. Run build_docker_image first."
        exit 1
    fi
    
     if gcloud container images describe "$IMAGE_TAG_FULL" >/dev/null 2>&1; then
        echo "Image verified in registry: $IMAGE_TAG_FULL"
    else
        echo "Failed to verify image in registry"
        exit 1
    fi
}

setup_environment() {
    echo "Setting up environment..."
    
    mkdir -p logs
    mkdir -p artifacts
    
    
    echo "Environment: $ENVIRONMENT"
    echo "Project ID: $PROJECT_ID"
    echo "Registry: $REGISTRY"
    echo "Service: $SERVICE"
}

cleanup() {
    echo "🧹 Cleaning up..."
    
    if [[ -f "/tmp/gcp-key.json" ]]; then
        rm -f /tmp/gcp-key.json
    fi
    
    echo "Cleanup completed"
}

error_handler() {
    echo "Build failed at line $1"
    cleanup
    exit 1
}

trap 'error_handler $LINENO' ERR

main() {
    echo "=========================================="
    echo "   BUILD STAGE - $ENVIRONMENT  STARTED    "
    echo "=========================================="
    
    setup_environment
    authenticate_gcp
    setup_cloud_sdk
    build_docker_image
    push_docker_image
    verify_image
    cleanup
    
    echo "=========================================="
    echo "    BUILD COMPLETED SUCCESSFULLY"
    echo "=========================================="
}

main "$@"
