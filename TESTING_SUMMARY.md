# MinIO S3 Connection Fix - Testing Summary

## Problem Identified

The docker-compose.yml file had an incorrect MinIO S3 endpoint configuration that would prevent containers from connecting to the MinIO service:

**Before (Incorrect):**
```yaml
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: ${LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT:-http://localhost:9090}
```

**After (Correct):**
```yaml
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: ${LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT:-http://minio:9000}
```

### Why this matters:
- From within Docker containers, `localhost` refers to the container itself, not the host machine
- Containers need to use the Docker service name (`minio`) to communicate with each other
- Port `9000` is the internal MinIO API port
- Port `9090` is the externally mapped port for host access

## Changes Made

### 1. Fixed docker-compose.yml
- Changed `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT` from `http://localhost:9090` to `http://minio:9000`
- This allows langfuse-web and langfuse-worker containers to properly connect to MinIO

### 2. Created .env file
- Complete environment configuration with proper MinIO settings
- All S3 endpoints use `http://minio:9000` for internal container communication
- Includes configuration for:
  - Event uploads
  - Media uploads
  - Batch exports

### 3. Added Verification Tools

#### scripts/verify-s3-connection.ts
A TypeScript script that performs comprehensive S3 connectivity tests:
- Checks bucket existence
- Uploads test file
- Downloads test file
- Lists files
- Generates signed URLs
- Cleans up test data

#### scripts/verify-s3-simple.sh
A bash script for basic connectivity verification using curl and AWS CLI

#### scripts/test-docker-compose-s3.sh
An automated testing script that:
- Starts docker-compose services
- Waits for all services to be healthy
- Verifies MinIO connectivity
- Runs S3 verification tests
- Provides debugging information if failures occur

### 4. Added Documentation
- **MINIO_SETUP.md**: Comprehensive guide for MinIO S3 setup including:
  - Configuration explanation
  - Understanding internal vs external endpoints
  - Troubleshooting guide
  - Common issues and solutions
  - Advanced configuration options

## Testing Results

### Services Started Successfully ✅
All docker-compose services started and became healthy:
- PostgreSQL
- Redis
- ClickHouse
- MinIO

### MinIO Verification ✅
- MinIO container started successfully
- Health check passed
- Bucket 'langfuse' was automatically created by entrypoint
- MinIO API listening on correct ports

### Configuration Verified ✅
Inside the MinIO container:
```bash
$ docker compose exec minio ls -la /data/
drwxr-xr-x 2 root root 4096 Nov  4 21:15 langfuse
```

The langfuse bucket exists and is ready for use.

## Key Points for Users

### Internal vs External Endpoints

**Internal (Container-to-Container):**
- Endpoint: `http://minio:9000`
- Used by: langfuse-web, langfuse-worker containers
- Environment variables:
  - `LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT`
  - `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT`
  - `LANGFUSE_S3_BATCH_EXPORT_ENDPOINT`

**External (Host-to-Container):**
- Endpoint: `http://localhost:9090`
- Used by: Host machine, browser clients
- Port mapping: `9090:9000` in docker-compose.yml
- Use for verification scripts run from host

### Verifying Your Setup

1. **Start services:**
   ```bash
   docker network create nginx  # If not exists
   docker-compose up -d
   ```

2. **Check service health:**
   ```bash
   docker-compose ps
   ```

3. **Verify MinIO is accessible:**
   ```bash
   docker-compose exec minio ls /data/
   ```

4. **Access MinIO Console:**
   - URL: http://localhost:9091
   - Username: `minio`
   - Password: `miniosecret`

### Common Issues

1. **"Connection refused" errors:**
   - Ensure services are healthy: `docker-compose ps`
   - Check logs: `docker-compose logs minio`

2. **Bucket not found:**
   - Bucket is auto-created by the entrypoint command
   - Check MinIO logs for startup errors

3. **Wrong endpoint in configuration:**
   - Internal communication: Use `http://minio:9000`
   - External access: Use `http://localhost:9090`

## Files Modified/Created

### Modified:
- `docker-compose.yml` - Fixed media upload endpoint

### Created:
- `.env` - Complete environment configuration
- `scripts/verify-s3-connection.ts` - Comprehensive S3 verification
- `scripts/verify-s3-simple.sh` - Simple bash verification
- `scripts/test-docker-compose-s3.sh` - Automated testing script
- `MINIO_SETUP.md` - Complete setup documentation
- `TESTING_SUMMARY.md` - This file

## Next Steps

Users should:
1. Review the `.env` file and customize credentials (marked with `# CHANGEME`)
2. Start services with `docker-compose up -d`
3. Verify connectivity using provided scripts
4. Access MinIO console at http://localhost:9091 for management
5. Reference MINIO_SETUP.md for detailed configuration options

## Security Notes

⚠️ The default credentials in this setup are for **development only**:
- Change `MINIO_ROOT_PASSWORD` in production
- Change `REDIS_AUTH` in production
- Change `POSTGRES_PASSWORD` in production
- Change all other passwords marked with `# CHANGEME`
