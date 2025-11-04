# Troubleshooting MinIO Credentials

## Common Issue: SignatureDoesNotMatch Error

If you're seeing this error:
```
SignatureDoesNotMatch: The request signature we calculated does not match the signature you provided. Check your key and signing method.
```

This means the credentials in your `.env` file don't match the credentials MinIO is using.

## Root Cause

MinIO uses **root credentials** set via:
- `MINIO_ROOT_USER` (default: `minio`)
- `MINIO_ROOT_PASSWORD` (default: `miniosecret`)

Your S3 configuration must use the **same credentials**:
- `LANGFUSE_S3_*_ACCESS_KEY_ID` must match `MINIO_ROOT_USER`
- `LANGFUSE_S3_*_SECRET_ACCESS_KEY` must match `MINIO_ROOT_PASSWORD`

## How to Fix

### Option 1: Use Default Credentials (Recommended for Testing)

Set MinIO credentials in your `.env`:
```bash
# MinIO Root Credentials
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=miniosecret

# S3 Event Upload (must match MinIO root credentials)
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=miniosecret

# S3 Media Upload (must match MinIO root credentials)
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=miniosecret

# S3 Batch Export (must match MinIO root credentials)
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minio
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=miniosecret
```

### Option 2: Use Custom Credentials (Recommended for Production)

If you want to use custom credentials like `oOBBouDRIAEMLxNudUy3L96QorNN/CLlRZza8Fx4hD8=`, you must:

1. **Set the same credentials for MinIO:**
```bash
# MinIO Root Credentials
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=oOBBouDRIAEMLxNudUy3L96QorNN/CLlRZza8Fx4hD8=
```

2. **Use them in all S3 configurations:**
```bash
# S3 Event Upload
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=oOBBouDRIAEMLxNudUy3L96QorNN/CLlRZza8Fx4hD8=

# S3 Media Upload
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=oOBBouDRIAEMLxNudUy3L96QorNN/CLlRZza8Fx4hD8=

# S3 Batch Export
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minio
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=oOBBouDRIAEMLxNudUy3L96QorNN/CLlRZza8Fx4hD8=
```

## Common Typos to Fix

If you have batch export configuration, make sure the variable names are correct:

❌ **Wrong:**
```bash
LANGFUSE_S3_BATCH_UPLOAD_SECRET_ACCESS_KEY=...
LANGFUSE_S3_BATCH_UPLOAD_ENDPOINT=...
LANGFUSE_S3_BATCH_UPLOAD_FORCE_PATH_STYLE=...
LANGFUSE_S3_BATCH_UPLOAD_PREFIX=...
```

✅ **Correct:**
```bash
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=...
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=...
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=...
LANGFUSE_S3_BATCH_EXPORT_PREFIX=...
```

## Complete Working Example

Here's a complete `.env` configuration that works:

```bash
# Database
DATABASE_URL=******postgres:5432/postgres

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=mysecret

# Encryption
SALT=mysalt
ENCRYPTION_KEY=0000000000000000000000000000000000000000000000000000000000000000

# ClickHouse
CLICKHOUSE_MIGRATION_URL=clickhouse://clickhouse:9000
CLICKHOUSE_URL=http://clickhouse:8123
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=clickhouse
CLICKHOUSE_CLUSTER_ENABLED=false

# MinIO Root Credentials (IMPORTANT: These must match S3 credentials below)
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=miniosecret

# S3 Event Upload Configuration
LANGFUSE_S3_EVENT_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_EVENT_UPLOAD_REGION=us-east-1
LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_EVENT_UPLOAD_PREFIX=events/

# S3 Media Upload Configuration
LANGFUSE_S3_MEDIA_UPLOAD_BUCKET=langfuse
LANGFUSE_S3_MEDIA_UPLOAD_REGION=us-east-1
LANGFUSE_S3_MEDIA_UPLOAD_ACCESS_KEY_ID=minio
LANGFUSE_S3_MEDIA_UPLOAD_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_MEDIA_UPLOAD_ENDPOINT=http://minio:9000
LANGFUSE_S3_MEDIA_UPLOAD_FORCE_PATH_STYLE=true
LANGFUSE_S3_MEDIA_UPLOAD_PREFIX=media/

# S3 Batch Export Configuration
LANGFUSE_S3_BATCH_EXPORT_ENABLED=false
LANGFUSE_S3_BATCH_EXPORT_BUCKET=langfuse
LANGFUSE_S3_BATCH_EXPORT_REGION=us-east-1
LANGFUSE_S3_BATCH_EXPORT_ACCESS_KEY_ID=minio
LANGFUSE_S3_BATCH_EXPORT_SECRET_ACCESS_KEY=miniosecret
LANGFUSE_S3_BATCH_EXPORT_ENDPOINT=http://minio:9000
LANGFUSE_S3_BATCH_EXPORT_EXTERNAL_ENDPOINT=http://localhost:9090
LANGFUSE_S3_BATCH_EXPORT_FORCE_PATH_STYLE=true
LANGFUSE_S3_BATCH_EXPORT_PREFIX=exports/

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_AUTH=myredissecret

# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
```

## Verification Steps

After updating your `.env` file:

1. **Restart services:**
```bash
docker-compose down
docker-compose up -d
```

2. **Check MinIO logs:**
```bash
docker-compose logs minio | tail -20
```

3. **Verify credentials are loaded:**
```bash
docker-compose exec minio env | grep MINIO_ROOT
```

4. **Test S3 connectivity:**
```bash
# Check if bucket exists
docker-compose exec minio ls /data/
```

## Quick Checklist

- [ ] `MINIO_ROOT_USER` matches all `LANGFUSE_S3_*_ACCESS_KEY_ID` values
- [ ] `MINIO_ROOT_PASSWORD` matches all `LANGFUSE_S3_*_SECRET_ACCESS_KEY` values
- [ ] All S3 regions are set to `us-east-1` (not `auto`)
- [ ] All S3 endpoints use `http://minio:9000` (not `localhost`)
- [ ] All S3 force path style is set to `true`
- [ ] No typos in variable names (especially batch export)
- [ ] Services restarted after changing `.env`

## Still Having Issues?

If you're still seeing signature errors after verifying credentials match:

1. Check for special characters in passwords that might need escaping
2. Ensure there are no extra spaces or quotes around values
3. Verify the `.env` file is in the same directory as `docker-compose.yml`
4. Try using simple passwords first (like `miniosecret`) to rule out encoding issues
5. Check MinIO container logs for authentication errors: `docker-compose logs minio`
