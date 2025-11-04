# MinIO S3 Setup Guide

This guide explains how to set up and verify MinIO S3 connectivity with Langfuse using docker-compose.

## Overview

Langfuse uses S3-compatible storage (MinIO in local/docker setups) for:
- **Event Uploads**: Storing trace and observation events
- **Media Uploads**: Storing media files and attachments
- **Batch Exports**: Exporting data in batch operations

## Quick Start

### 1. Prerequisites

- Docker and Docker Compose installed
- Node.js (optional, for running verification scripts)

### 2. Configuration

The repository includes a `.env` file with proper MinIO configuration. Key settings:

```bash
# MinIO S3 Configuration
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000  # Internal endpoint
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true

# MinIO Root Credentials
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=miniosecret
```

### 3. Start Services

```bash
# Create external network (if not exists)
docker network create nginx

# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

### 4. Verify S3 Connection

#### Option A: Automated Test Script

```bash
./scripts/test-docker-compose-s3.sh
```

This script will:
- Start docker-compose services
- Wait for all services to be healthy
- Test MinIO connectivity
- Run S3 verification tests
- Display service URLs and credentials

#### Option B: Manual Verification

```bash
# From host machine (external access)
export LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT="http://localhost:9090"
export LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID="minio"
export LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY="miniosecret"
export LANGFUSE_S3_EVENT_UPLOAD_BUCKET="langfuse"
export LANGFUSE_S3_EVENT_UPLOAD_REGION="us-east-1"
export LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE="true"

npx tsx scripts/verify-s3-connection.ts
```

## Understanding Endpoints

### Internal vs External Endpoints

MinIO in docker-compose has two types of endpoints:

1. **Internal Endpoint** (container-to-container): `http://minio:9000`
   - Used by langfuse-web and langfuse-worker containers
   - Configured in `LANGFUSE_S3_*_ENDPOINT` variables

2. **External Endpoint** (host-to-container): `http://localhost:9090`
   - Used for accessing MinIO from your host machine
   - Used for generating signed URLs that work from browser
   - Port mapped in docker-compose.yml: `9090:9000`

### Common Configuration Issues

❌ **Wrong**: Setting internal endpoint to `localhost`
```yaml
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: http://localhost:9090
```

✅ **Correct**: Using service name for internal endpoint
```yaml
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: http://minio:9000
```

## Service URLs

After starting docker-compose:

- **Langfuse Web UI**: http://localhost:3000
- **MinIO Console**: http://localhost:9091
  - Username: `minio`
  - Password: `miniosecret`
- **MinIO API (External)**: http://localhost:9090
- **MinIO API (Internal)**: http://minio:9000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **ClickHouse**: localhost:8123

## Troubleshooting

### Services not starting

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs minio
docker-compose logs langfuse-web
docker-compose logs langfuse-worker

# Restart services
docker-compose restart
```

### S3 Connection Errors

1. **"Connection refused" or "ECONNREFUSED"**
   - MinIO service is not running
   - Check: `docker-compose ps minio`
   - Solution: Ensure MinIO is healthy

2. **"Access Denied" or "InvalidAccessKeyId"**
   - Credentials mismatch between .env and docker-compose.yml
   - Check: Verify `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`
   - Solution: Ensure credentials match in all configurations

3. **"Bucket does not exist"**
   - The langfuse bucket was not created
   - Solution: The bucket is auto-created by the entrypoint command in docker-compose.yml
   - Check: `docker-compose logs minio` for startup errors

4. **"Network error" or "EAI_AGAIN"**
   - DNS resolution issues
   - Solution: Ensure all services are on the same Docker network

### Verify MinIO Health

```bash
# Check MinIO health endpoint
curl http://localhost:9090/minio/health/live

# Access MinIO console
open http://localhost:9091
```

### Reset Everything

```bash
# Stop and remove all services and volumes
docker-compose down -v

# Remove network
docker network rm nginx

# Start fresh
docker network create nginx
docker-compose up -d
```

## Advanced Configuration

### Using External S3 Endpoint for Signed URLs

For production setups where signed URLs need to be accessible from external clients:

```yaml
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT: http://minio:9000  # Internal
LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT: https://your-domain.com/s3  # External
```

### Custom Bucket Names

Edit `.env` to use different bucket names:

```bash
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=my-events-bucket
LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=my-media-bucket
LANGFUSE_S3_BATCH_EXPORT_BUCKET=my-exports-bucket
```

Note: You'll need to create these buckets manually or update the MinIO entrypoint command in docker-compose.yml.

### Using AWS S3 Instead of MinIO

To use real AWS S3:

```bash
# Remove MinIO endpoint
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=

# Set AWS region
LANGFUSE_S3_EVENT_UPLOAD_REGION=us-east-1

# Use AWS credentials
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=your_aws_access_key
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=your_aws_secret_key

# Disable path style (AWS S3 uses virtual-hosted-style)
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=false
```

## Files Modified

- `docker-compose.yml` - Fixed `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT` to use `http://minio:9000`
- `.env` - Created with proper MinIO configuration
- `scripts/verify-s3-connection.ts` - S3 connection verification script
- `scripts/test-docker-compose-s3.sh` - Automated docker-compose test script

## Additional Resources

- [MinIO Documentation](https://min.io/docs/)
- [AWS S3 SDK for JavaScript](https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/clients/client-s3/)
- [Langfuse Documentation](https://langfuse.com/docs)
