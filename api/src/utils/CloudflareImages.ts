import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { Buffer } from 'buffer';

export async function uploadImageToCloudflare(base64: string, filename: string): Promise<string> {
  const accountId = process.env.CF_R2_ACCOUNT_ID;
  const accessKeyId = process.env.CF_R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.CF_R2_SECRET_ACCESS_KEY;
  const bucketName = process.env.CF_R2_BUCKET_NAME;
  const publicUrl = process.env.CF_R2_PUBLIC_URL;

  if (!accountId || !accessKeyId || !secretAccessKey || !bucketName || !publicUrl) {
    throw new Error('Cloudflare R2 configuration is missing (CF_R2_ACCOUNT_ID, CF_R2_ACCESS_KEY_ID, CF_R2_SECRET_ACCESS_KEY, CF_R2_BUCKET_NAME, CF_R2_PUBLIC_URL)');
  }

  // Support data URLs (data:<mime>;base64,<data>) or raw base64
  const match = base64.match(/^data:(.+);base64,(.+)$/);
  let contentType = 'image/jpeg';
  let data = base64;
  if (match) {
    contentType = match[1];
    data = match[2];
  }

  const buffer = Buffer.from(data, 'base64');

  // Create S3 client for Cloudflare R2
  const client = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId,
      secretAccessKey,
    },
  });

  try {
    await client.send(
      new PutObjectCommand({
        Bucket: bucketName,
        Key: filename,
        Body: buffer,
        ContentType: contentType,
      })
    );

    // Return the public URL to the uploaded file
    return `${publicUrl}/${filename}`;
  } finally {
    client.destroy();
  }
}

export default uploadImageToCloudflare;
