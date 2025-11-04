#!/bin/bash

# Test Docker Compose S3 Setup Script
# This script spins up docker-compose and verifies S3 connectivity

set -e

echo "🐳 Docker Compose S3 Test Script"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        print_error "docker-compose or 'docker compose' command not found!"
        exit 1
    else
        COMPOSE_CMD="docker compose"
    fi
else
    COMPOSE_CMD="docker-compose"
fi

print_success "Docker Compose command: $COMPOSE_CMD"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    print_error ".env file not found!"
    echo "Please create a .env file with proper configuration."
    exit 1
fi

print_success ".env file found"
echo ""

# Create external network if it doesn't exist
print_info "Checking for external nginx network..."
if ! docker network inspect nginx &> /dev/null; then
    print_info "Creating external nginx network..."
    docker network create nginx
    print_success "nginx network created"
else
    print_success "nginx network already exists"
fi
echo ""

# Spin up docker-compose services
print_info "Starting Docker Compose services..."
$COMPOSE_CMD up -d

# Wait for services to be healthy
print_info "Waiting for services to become healthy..."
echo ""

# Function to check service health
check_service_health() {
    local service=$1
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        health_status=$($COMPOSE_CMD ps --format json "$service" 2>/dev/null | grep -o '"Health":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        state=$($COMPOSE_CMD ps --format json "$service" 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4 || echo "unknown")
        
        if [ "$health_status" = "healthy" ] || ([ "$state" = "running" ] && [ -z "$health_status" ]); then
            print_success "$service is healthy"
            return 0
        fi
        
        if [ "$state" = "exited" ] || [ "$state" = "dead" ]; then
            print_error "$service has exited or is dead"
            return 1
        fi
        
        attempt=$((attempt + 1))
        sleep 2
    done
    
    print_error "$service did not become healthy in time"
    return 1
}

# Check each critical service
services=("postgres" "redis" "clickhouse" "minio")
all_healthy=true

for service in "${services[@]}"; do
    if ! check_service_health "$service"; then
        all_healthy=false
    fi
done

echo ""

if [ "$all_healthy" = false ]; then
    print_error "Some services failed to start properly"
    echo ""
    print_info "Service status:"
    $COMPOSE_CMD ps
    echo ""
    print_info "Recent logs:"
    $COMPOSE_CMD logs --tail=50
    exit 1
fi

print_success "All services are healthy!"
echo ""

# Test MinIO connectivity from host
print_info "Testing MinIO connectivity from host..."
if command -v curl &> /dev/null; then
    if curl -sf http://localhost:9090/minio/health/live > /dev/null 2>&1; then
        print_success "MinIO is accessible from host at http://localhost:9090"
    else
        print_error "MinIO is not accessible from host at http://localhost:9090"
        print_info "Checking MinIO logs..."
        $COMPOSE_CMD logs minio --tail=20
    fi
else
    print_info "curl not available, skipping host connectivity test"
fi
echo ""

# Run S3 verification script from host
print_info "Running S3 verification script from host..."
if command -v node &> /dev/null; then
    # Set environment variables for host testing
    export LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT="http://localhost:9090"
    export LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID="minio"
    export LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY="miniosecret"
    export LANGFUSE_S3_EVENT_UPLOAD_BUCKET="langfuse"
    export LANGFUSE_S3_EVENT_UPLOAD_REGION="auto"
    export LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE="true"
    
    if npx tsx scripts/verify-s3-connection.ts; then
        print_success "S3 verification from host succeeded!"
    else
        print_error "S3 verification from host failed!"
        echo ""
        print_info "Debugging information:"
        echo "Docker Compose Services Status:"
        $COMPOSE_CMD ps
        echo ""
        echo "MinIO Logs:"
        $COMPOSE_CMD logs minio --tail=30
        exit 1
    fi
else
    print_info "Node.js not available, skipping S3 verification script"
fi
echo ""

# Display summary
echo "================================"
print_success "Docker Compose S3 Setup Complete!"
echo ""
print_info "Services are running at:"
echo "  - Langfuse Web: http://localhost:3000"
echo "  - MinIO Console: http://localhost:9091"
echo "  - MinIO API: http://localhost:9090"
echo "  - PostgreSQL: localhost:5432"
echo "  - Redis: localhost:6379"
echo "  - ClickHouse: localhost:8123"
echo ""
print_info "MinIO Credentials:"
echo "  - Access Key: minio"
echo "  - Secret Key: miniosecret"
echo ""
print_info "To view logs: $COMPOSE_CMD logs -f"
print_info "To stop services: $COMPOSE_CMD down"
echo ""
