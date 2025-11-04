#!/bin/bash

# Simple S3/MinIO Connection Verification Script
# Uses curl and AWS CLI (if available) to verify connectivity

set -e

echo "🔧 MinIO S3 Connection Verification"
echo "===================================="
echo ""

# Configuration
ENDPOINT="${LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT:-http://localhost:9090}"
ACCESS_KEY="${LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID:-minio}"
SECRET_KEY="${LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY:-miniosecret}"
BUCKET="${LANGFUSE_S3_EVENT_UPLOAD_BUCKET:-langfuse}"

echo "Configuration:"
echo "  Endpoint: $ENDPOINT"
echo "  Access Key: $ACCESS_KEY"
echo "  Bucket: $BUCKET"
echo ""

# Test 1: Check MinIO health endpoint
echo "📋 Test 1: Checking MinIO health endpoint..."
if curl -sf "$ENDPOINT/minio/health/live" > /dev/null 2>&1; then
    echo "✅ MinIO health endpoint is responsive"
else
    echo "❌ MinIO health endpoint is not accessible"
    echo "   Tried: $ENDPOINT/minio/health/live"
    exit 1
fi
echo ""

# Test 2: List buckets (if AWS CLI is available)
if command -v aws &> /dev/null; then
    echo "📋 Test 2: Listing buckets using AWS CLI..."
    
    export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
    export AWS_DEFAULT_REGION="auto"
    
    if aws --endpoint-url="$ENDPOINT" s3 ls 2>&1 | grep -q "$BUCKET"; then
        echo "✅ Bucket '$BUCKET' found"
    else
        echo "⚠️  Bucket '$BUCKET' not found, attempting to create it..."
        if aws --endpoint-url="$ENDPOINT" s3 mb "s3://$BUCKET" 2>&1; then
            echo "✅ Bucket '$BUCKET' created successfully"
        else
            echo "❌ Failed to create bucket '$BUCKET'"
        fi
    fi
    
    echo ""
    echo "📋 Test 3: Testing file upload..."
    TEST_FILE="/tmp/test-s3-$(date +%s).txt"
    echo "Test content from MinIO verification" > "$TEST_FILE"
    
    if aws --endpoint-url="$ENDPOINT" s3 cp "$TEST_FILE" "s3://$BUCKET/test/verify.txt" 2>&1; then
        echo "✅ File uploaded successfully"
        
        echo ""
        echo "📋 Test 4: Testing file download..."
        DOWNLOAD_FILE="/tmp/test-s3-download-$(date +%s).txt"
        
        if aws --endpoint-url="$ENDPOINT" s3 cp "s3://$BUCKET/test/verify.txt" "$DOWNLOAD_FILE" 2>&1; then
            echo "✅ File downloaded successfully"
            
            if cmp -s "$TEST_FILE" "$DOWNLOAD_FILE"; then
                echo "✅ Downloaded file matches uploaded file"
            else
                echo "❌ Downloaded file does not match uploaded file"
            fi
            
            rm -f "$DOWNLOAD_FILE"
        else
            echo "❌ Failed to download file"
        fi
        
        echo ""
        echo "📋 Test 5: Cleaning up test file..."
        if aws --endpoint-url="$ENDPOINT" s3 rm "s3://$BUCKET/test/verify.txt" 2>&1; then
            echo "✅ Test file deleted successfully"
        else
            echo "⚠️  Failed to delete test file"
        fi
        
        rm -f "$TEST_FILE"
    else
        echo "❌ Failed to upload file"
        rm -f "$TEST_FILE"
    fi
else
    echo "⚠️  AWS CLI not installed, skipping advanced tests"
    echo "   Install AWS CLI for more comprehensive testing:"
    echo "   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

echo ""
echo "✨ Basic connectivity tests passed! ✨"
echo ""
echo "Service URLs:"
echo "  - MinIO API: $ENDPOINT"
echo "  - MinIO Console: http://localhost:9091"
echo ""
echo "To access MinIO Console:"
echo "  - Username: $ACCESS_KEY"
echo "  - Password: $SECRET_KEY"
echo ""
