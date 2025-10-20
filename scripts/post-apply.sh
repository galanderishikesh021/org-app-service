#!/bin/bash

# Post-Apply Stage Script

set -e 

ENVIRONMENT=$1
PROJECT_ID=$PROJECT_ID
GKE_CLUSTER=$GKE_CLUSTER
GKE_ZONE=$GKE_ZONE
SERVICE=$SERVICE
TIMEOUT=$TIMEOUT
SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_UR

echo "Starting post-apply verification for environment: $ENVIRONMENT"

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

verify_deployment() {
    echo "Verifying deployment..."
    
    if ! command_exists kubectl; then
        echo "kubectl not found. Please install kubectl"
        exit 1
    fi
    
    echo "Checking Kubernetes resources in namespace: $ENVIRONMENT"
    
    echo "Pods:"
    kubectl get pods -n "$ENVIRONMENT" -o wide
    
    echo "Services:"
    kubectl get services -n "$ENVIRONMENT"
    
    echo "Ingress:"
    kubectl get ingress -n "$ENVIRONMENT"
    
    echo "Deployments:"
    kubectl get deployments -n "$ENVIRONMENT"
    
    echo "Deployment verification completed"
}

wait_for_deployment() {
    echo "Waiting for deployment to be ready..."
    
    if ! command_exists kubectl; then
        echo "kubectl not found. Skipping deployment readiness check."
        return 0
    fi
    
    kubectl wait --for=condition=available \
        --timeout="${TIMEOUT}s" \
        deployment/"$SERVICE" \
        -n "$ENVIRONMENT"
    
    echo "Deployment is ready"
}

get_service_endpoint() {
    echo "Getting service endpoint..."
    
    if ! command_exists kubectl; then
        echo "kubectl not found. Cannot get service endpoint."
        return 1
    fi
    
    SERVICE_IP=$(kubectl get service "$SERVICE" -n "$ENVIRONMENT" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [[ -n "$SERVICE_IP" ]]; then
        echo "Service IP: $SERVICE_IP"
        export SERVICE_ENDPOINT="http://$SERVICE_IP"
        return 0
    fi
    
    NODE_PORT=$(kubectl get service "$SERVICE" -n "$ENVIRONMENT" \
        -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
    
    if [[ -n "$NODE_PORT" ]]; then
        echo "NodePort: $NODE_PORT"
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || echo "")
        if [[ -n "$NODE_IP" ]]; then
            export SERVICE_ENDPOINT="http://$NODE_IP:$NODE_PORT"
            return 0
        fi
    fi
    
    echo "Could not get external endpoint. use port-forward:"
    echo "   kubectl port-forward service/$SERVICE 8080:80 -n $ENVIRONMENT"
    echo "   Then test with: curl http://localhost:8080/health"
    
    return 1
}

run_health_checks() {
    echo "Running health checks..."
    
    if [[ -z "$SERVICE_ENDPOINT" ]]; then
        echo "No service endpoint available. Skipping health checks."
        return 0
    fi
    
    echo "Testing health endpoint: $SERVICE_ENDPOINT/health"
    if curl -f -s "$SERVICE_ENDPOINT/health" >/dev/null; then
        echo "Health check passed"
    else
        echo "Health check failed"
        return 1
    fi
    
    echo "Testing ready endpoint: $SERVICE_ENDPOINT/api/ready"
    if curl -f -s "$SERVICE_ENDPOINT/api/ready" >/dev/null; then
        echo "Ready check passed"
    else
        echo "Ready check failed or endpoint not available"
    fi
    
    echo "Health checks completed"
}

run_smoke_tests() {
    echo "Running smoke tests..."
    
    if [[ -z "$SERVICE_ENDPOINT" ]]; then
        echo "No service endpoint available. Skipping smoke tests."
        return 0
    fi
    
    echo "Testing basic connectivity..."
    if curl -f -s "$SERVICE_ENDPOINT/" >/dev/null; then
        echo "Basic connectivity test passed"
    else
        echo "Basic connectivity test failed"
        return 1
    fi
    
    echo "Smoke tests completed"
}


send_slack_notification() {
    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        echo "Slack webhook URL not provided. Skipping notification."
        return 0
    fi
    
    echo "Sending Slack notification..."
    
    local status=$1
    local message="Deployment to $ENVIRONMENT $status for commit $GITHUB_SHA"
    
    local channel
    case "$ENVIRONMENT" in
        "prod")
            channel="#prod-deployments"
            ;;
        "staging")
            channel="#staging-deployments"
            ;;
        "dev")
            channel="#dev-deployments"
            ;;
        *)
            channel="#deployments"
            ;;
    esac
    
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"channel\":\"$channel\",\"text\":\"$message\"}" \
        "$SLACK_WEBHOOK_URL"
    
    echo "Slack notification sent"
}

setup_environment() {
    echo "Setting up environment..."
    
    mkdir -p logs
    mkdir -p artifacts
    
    echo "Environment: $ENVIRONMENT"
    echo "Project ID: $PROJECT_ID"
    echo "GKE Cluster: $GKE_CLUSTER"
    echo "GKE Zone: $GKE_ZONE"
    echo "Service: $SERVICE"
    echo "Timeout: $TIMEOUT seconds"
    echo "Commit SHA: $GITHUB_SHA"
}

cleanup() {
    echo "Cleaning up..."
    
    if [[ -f "/tmp/gcp-key.json" ]]; then
        rm -f /tmp/gcp-key.json
    fi
    
    echo "Cleanup completed"
}

error_handler() {
    echo "Post-apply verification failed at line $1"
    send_slack_notification "failed"
    cleanup
    exit 1
}

trap 'error_handler $LINENO' ERR

main() {
    echo "=========================================="
    echo "POST-APPLY STAGE - $ENVIRONMENT  STARTED  "
    echo "=========================================="
    
    setup_environment
    authenticate_gcp
    setup_cloud_sdk
    get_gke_credentials
    verify_deployment
    wait_for_deployment
    get_service_endpoint
    run_health_checks
    run_smoke_tests
    send_slack_notification "completed successfully"
    cleanup
    
    echo "==============================================="
    echo "POST-APPLY VERIFICATION COMPLETED SUCCESSFULLY "
    echo "==============================================="
}

main "$@"
