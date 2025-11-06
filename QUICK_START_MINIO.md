# Quick Start: MinIO S3 with Langfuse

This is a quick reference guide to get MinIO S3 working with Langfuse using docker-compose.

## The Problem (Now Fixed!)

The docker-compose.yml had an incorrect S3 endpoint that prevented containers from connecting to MinIO:

❌ **Was:** `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: http://localhost:9090`  
✅ **Now:** `LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT: http://minio:9000`

## Quick Setup (3 Steps)

### 1. Copy the example environment file

```bash
cp .env.minio.example .env
```

### 2. (Optional) Customize credentials

Edit `.env` and change passwords marked with `# CHANGEME`:
- `MINIO_ROOT_PASSWORD`
- `POSTGRES_PASSWORD`
- `REDIS_AUTH`
- etc.

### 3. Start services

```bash
# Create external network (one-time only)
docker network create nginx

# Start all services
docker-compose up -d

# Check status
docker-compose ps
```

## Verify It's Working

### Quick Check:
```bash
# Check all services are healthy
docker-compose ps

# Verify MinIO bucket exists
docker-compose exec minio ls /data/
# Should show: langfuse directory
```

### Access MinIO Console:
- URL: http://localhost:9091
- Username: `minio`
- Password: `miniosecret`

### Run Verification Script:
```bash
./scripts/test-docker-compose-s3.sh
```

## Key Endpoints

| Service | Internal (Container) | External (Host) |
|---------|---------------------|-----------------|
| MinIO API | `http://minio:9000` | `http://localhost:9090` |
| MinIO Console | - | `http://localhost:9091` |
| Langfuse Web | - | `http://localhost:3000` |
| PostgreSQL | `postgres:5432` | `localhost:5432` |
| Redis | `redis:6379` | `localhost:6379` |
| ClickHouse | `clickhouse:8123` | `localhost:8123` |

## Understanding Endpoints

**Why two endpoints?**

1. **Internal (`http://minio:9000`)**: 
   - Used by containers to talk to each other
   - Configured in environment variables
   - Uses Docker's internal networking

2. **External (`http://localhost:9090`)**: 
   - Used by your browser/host machine
   - Port mapping in docker-compose.yml: `9090:9000`
   - For accessing MinIO Console and verification

## Common Issues

### "Connection refused" errors
```bash
# Check if services are running
docker-compose ps

# View logs
docker-compose logs minio
```

### "Bucket not found"
The bucket is auto-created by MinIO's entrypoint. Check:
```bash
docker-compose exec minio ls /data/
```

### SignatureDoesNotMatch errors
**Most common cause:** MinIO credentials don't match S3 configuration.

✅ **Fix:** Ensure these match in your `.env`:
```bash
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=miniosecret

# All S3 configs must use the same credentials
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=miniosecret
```

📖 See [TROUBLESHOOTING_MINIO_CREDENTIALS.md](./TROUBLESHOOTING_MINIO_CREDENTIALS.md) for detailed help.

## Next Steps

- 📖 Read [MINIO_SETUP.md](./MINIO_SETUP.md) for detailed configuration
- 📋 Check [TESTING_SUMMARY.md](./TESTING_SUMMARY.md) for testing results
- 🔧 Use verification scripts in `scripts/` directory

## Stop Services

```bash
# Stop and keep data
docker-compose down

# Stop and remove all data
docker-compose down -v
```

## Need Help?

1. Check logs: `docker-compose logs [service-name]`
2. Verify configuration in `.env`
3. Ensure endpoints match (internal vs external)
4. Review [MINIO_SETUP.md](./MINIO_SETUP.md) troubleshooting section

---

**Note:** Default credentials are for **development only**. Change them for production use!
