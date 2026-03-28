#!/usr/bin/env bash

# ECS Service Management Script
# Usage: ./ecssvc.sh [OPTIONS] COMMAND
# Commands: status, up, down
# Options: -s SERVICE_NAME, -c CLUSTER_NAME

set -e

# Default values
SERVICE_NAME=""
CLUSTER_NAME="ecs-cluster-dev"
COMMAND=""

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  status    Show current service status (all services if no -s specified)"
    echo "  up        Set desired count to 1 (requires -s SERVICE_NAME)"
    echo "  down      Set desired count to 0 (requires -s SERVICE_NAME)"
    echo ""
    echo "Options:"
    echo "  -s SERVICE_NAME    Target service name (required for up/down)"
    echo "  -c CLUSTER_NAME    ECS cluster name (default: 'default')"
    echo "  -h                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status                    # List all services"
    echo "  $0 -s my-service status      # Show specific service"
    echo "  $0 -s my-service -c my-cluster up"
    echo "  $0 -s my-service down"
    exit 1
}

# Function to check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS CLI is not configured or credentials are invalid"
        exit 1
    fi
}

# Function to get service status
get_service_status() {
    local service_name="$1"
    local cluster_name="$2"
    
    if [ -n "$service_name" ]; then
        # Get specific service status
        echo "ECS Service Status"
        echo "=================="
        printf "%-30s %-15s %-15s %-15s %-15s\n" "SERVICE" "CLUSTER" "DESIRED" "RUNNING" "PENDING"
        printf "%-30s %-15s %-15s %-15s %-15s\n" "------------------------------" "---------------" "---------------" "---------------" "---------------"
        
        # Get service details
        local service_info=$(aws ecs describe-services \
            --cluster "$cluster_name" \
            --services "$service_name" \
            --query 'services[0].{desired:desiredCount,running:runningCount,pending:pendingCount}' \
            --output json 2>/dev/null)
        
        if [ "$service_info" = "null" ] || [ -z "$service_info" ]; then
            printf "%-30s %-15s %-15s %-15s %-15s\n" "$service_name" "$cluster_name" "NOT FOUND" "NOT FOUND" "NOT FOUND"
            return 1
        fi
        
        local desired=$(echo "$service_info" | jq -r '.desired')
        local running=$(echo "$service_info" | jq -r '.running')
        local pending=$(echo "$service_info" | jq -r '.pending')
        
        printf "%-30s %-15s %-15s %-15s %-15s\n" "$service_name" "$cluster_name" "$desired" "$running" "$pending"
    else
        # List all services in the cluster
        echo "ECS Services Status"
        echo "==================="
        printf "%-30s %-15s %-15s %-15s %-15s\n" "SERVICE" "CLUSTER" "DESIRED" "RUNNING" "PENDING"
        printf "%-30s %-15s %-15s %-15s %-15s\n" "------------------------------" "---------------" "---------------" "---------------" "---------------"
        
        # Get all service ARNs
        local service_arns=$(aws ecs list-services \
            --cluster "$cluster_name" \
            --query 'serviceArns' \
            --output json 2>/dev/null)
        
        if [ "$service_arns" = "null" ] || [ -z "$service_arns" ] || [ "$service_arns" = "[]" ]; then
            printf "%-30s %-15s %-15s %-15s %-15s\n" "No services found" "$cluster_name" "-" "-" "-"
            return 0
        fi
        
        # Get service details for all services
        local services_info=$(aws ecs describe-services \
            --cluster "$cluster_name" \
            --services $(echo "$service_arns" | jq -r '.[] | split("/") | .[-1]' | tr '\n' ' ') \
            --query 'services[].{name:serviceName,desired:desiredCount,running:runningCount,pending:pendingCount}' \
            --output json 2>/dev/null)
        
        # Parse and display each service
        echo "$services_info" | jq -r '.[] | "\(.name) \(.desired) \(.running) \(.pending)"' | while read -r name desired running pending; do
            printf "%-30s %-15s %-15s %-15s %-15s\n" "$name" "$cluster_name" "$desired" "$running" "$pending"
        done
    fi
}

# Function to update service desired count
update_service_count() {
    local service_name="$1"
    local cluster_name="$2"
    local desired_count="$3"
    local action="$4"
    
    echo "Updating service: $service_name"
    echo "Action: $action (setting desired count to $desired_count)"
    echo ""
    
    # Update the service
    aws ecs update-service \
        --cluster "$cluster_name" \
        --service "$service_name" \
        --desired-count "$desired_count" \
        --output table \
        --query 'service.{ServiceName:serviceName,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount,Status:status}'
    
    echo ""
    echo "Service update initiated successfully!"
}

# Parse command line arguments
while getopts "s:c:h" opt; do
    case $opt in
        s)
            SERVICE_NAME="$OPTARG"
            ;;
        c)
            CLUSTER_NAME="$OPTARG"
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Shift past the options
shift $((OPTIND-1))

# Get the command
COMMAND="$1"

# Validate inputs
if [ "$COMMAND" = "up" ] || [ "$COMMAND" = "down" ]; then
    if [ -z "$SERVICE_NAME" ]; then
        echo "Error: Service name is required for $COMMAND command (-s SERVICE_NAME)"
        usage
    fi
fi

if [ -z "$COMMAND" ]; then
    echo "Error: Command is required (status, up, or down)"
    usage
fi

# Check AWS CLI
check_aws_cli

# Execute command
case "$COMMAND" in
    status)
        get_service_status "$SERVICE_NAME" "$CLUSTER_NAME"
        ;;
    up)
        update_service_count "$SERVICE_NAME" "$CLUSTER_NAME" 1 "UP"
        ;;
    down)
        update_service_count "$SERVICE_NAME" "$CLUSTER_NAME" 0 "DOWN"
        ;;
    *)
        echo "Error: Invalid command '$COMMAND'. Use 'status', 'up', or 'down'"
        usage
        ;;
esac
