#!/usr/bin/env tsx

/**
 * S3 Connection Verification Script
 * 
 * This script verifies that the MinIO S3 setup is working correctly by:
 * 1. Testing connection to MinIO endpoint
 * 2. Creating a test bucket if it doesn't exist
 * 3. Uploading a test file
 * 4. Downloading the test file
 * 5. Listing files in the bucket
 * 6. Deleting the test file
 * 7. Generating signed URLs
 */

import {
  S3Client,
  CreateBucketCommand,
  HeadBucketCommand,
  PutObjectCommand,
  GetObjectCommand,
  ListObjectsV2Command,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

// Configuration from environment variables
const config = {
  endpoint: process.env.LANGFUSE_S3_EVENT_UPLOAD_ENDPOINT || "http://localhost:9090",
  accessKeyId: process.env.LANGFUSE_S3_EVENT_UPLOAD_ACCESS_KEY_ID || "minio",
  secretAccessKey: process.env.LANGFUSE_S3_EVENT_UPLOAD_SECRET_ACCESS_KEY || "miniosecret",
  bucket: process.env.LANGFUSE_S3_EVENT_UPLOAD_BUCKET || "langfuse",
  region: process.env.LANGFUSE_S3_EVENT_UPLOAD_REGION || "us-east-1",
  forcePathStyle: process.env.LANGFUSE_S3_EVENT_UPLOAD_FORCE_PATH_STYLE === "true" || true,
};

console.log("🔧 S3 Connection Configuration:");
console.log(`   Endpoint: ${config.endpoint}`);
console.log(`   Access Key ID: ${config.accessKeyId}`);
console.log(`   Bucket: ${config.bucket}`);
console.log(`   Region: ${config.region}`);
console.log(`   Force Path Style: ${config.forcePathStyle}`);
console.log("");

// Create S3 client
const s3Client = new S3Client({
  endpoint: config.endpoint,
  region: config.region,
  credentials: {
    accessKeyId: config.accessKeyId,
    secretAccessKey: config.secretAccessKey,
  },
  forcePathStyle: config.forcePathStyle,
});

async function verifyS3Connection() {
  console.log("🚀 Starting S3 Connection Verification...\n");

  try {
    // Step 1: Check if bucket exists
    console.log("📦 Step 1: Checking if bucket exists...");
    try {
      await s3Client.send(new HeadBucketCommand({ Bucket: config.bucket }));
      console.log(`✅ Bucket '${config.bucket}' exists\n`);
    } catch (error: any) {
      if (error.name === "NotFound") {
        console.log(`⚠️  Bucket '${config.bucket}' does not exist. Creating...`);
        await s3Client.send(new CreateBucketCommand({ Bucket: config.bucket }));
        console.log(`✅ Bucket '${config.bucket}' created successfully\n`);
      } else {
        throw error;
      }
    }

    // Step 2: Upload a test file
    console.log("📤 Step 2: Uploading test file...");
    const testKey = `test/verification-${Date.now()}.txt`;
    const testContent = "Hello from Langfuse S3 verification script!";
    
    await s3Client.send(
      new PutObjectCommand({
        Bucket: config.bucket,
        Key: testKey,
        Body: testContent,
        ContentType: "text/plain",
      })
    );
    console.log(`✅ Test file uploaded: ${testKey}\n`);

    // Step 3: Download the test file
    console.log("📥 Step 3: Downloading test file...");
    const getResponse = await s3Client.send(
      new GetObjectCommand({
        Bucket: config.bucket,
        Key: testKey,
      })
    );
    const downloadedContent = await getResponse.Body?.transformToString();
    
    if (downloadedContent === testContent) {
      console.log(`✅ Test file downloaded and content matches\n`);
    } else {
      console.log(`❌ Downloaded content does not match`);
      console.log(`   Expected: ${testContent}`);
      console.log(`   Got: ${downloadedContent}\n`);
    }

    // Step 4: List files
    console.log("📋 Step 4: Listing files in bucket...");
    const listResponse = await s3Client.send(
      new ListObjectsV2Command({
        Bucket: config.bucket,
        Prefix: "test/",
      })
    );
    
    const fileCount = listResponse.Contents?.length || 0;
    console.log(`✅ Found ${fileCount} file(s) with 'test/' prefix`);
    if (listResponse.Contents && listResponse.Contents.length > 0) {
      listResponse.Contents.slice(0, 5).forEach((item) => {
        console.log(`   - ${item.Key} (${item.Size} bytes)`);
      });
      if (fileCount > 5) {
        console.log(`   ... and ${fileCount - 5} more`);
      }
    }
    console.log("");

    // Step 5: Generate signed URL
    console.log("🔗 Step 5: Generating signed URL...");
    const signedUrl = await getSignedUrl(
      s3Client,
      new GetObjectCommand({
        Bucket: config.bucket,
        Key: testKey,
      }),
      { expiresIn: 3600 }
    );
    console.log(`✅ Signed URL generated successfully`);
    console.log(`   URL: ${signedUrl.substring(0, 100)}...\n`);

    // Step 6: Delete the test file
    console.log("🗑️  Step 6: Cleaning up test file...");
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: config.bucket,
        Key: testKey,
      })
    );
    console.log(`✅ Test file deleted\n`);

    // Success!
    console.log("✨ All S3 connection tests passed! ✨");
    console.log("Your MinIO S3 setup is working correctly.\n");
    
    return true;
  } catch (error: any) {
    console.error("❌ S3 Connection Verification Failed!");
    console.error(`   Error: ${error.message}`);
    
    if (error.Code) {
      console.error(`   Code: ${error.Code}`);
    }
    
    if (error.$metadata) {
      console.error(`   Status: ${error.$metadata.httpStatusCode}`);
    }
    
    console.error("\n💡 Troubleshooting tips:");
    console.error("   1. Ensure MinIO is running: docker-compose ps");
    console.error("   2. Check MinIO logs: docker-compose logs minio");
    console.error("   3. Verify credentials match between .env and docker-compose.yml");
    console.error("   4. Ensure endpoint is accessible from your current location");
    console.error("   5. If running from host, use http://localhost:9090");
    console.error("   6. If running from container, use http://minio:9000\n");
    
    return false;
  }
}

// Run verification
verifyS3Connection()
  .then((success) => {
    process.exit(success ? 0 : 1);
  })
  .catch((error) => {
    console.error("Unexpected error:", error);
    process.exit(1);
  });
