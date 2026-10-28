import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';

export const SANDBOX_BINDING = Object.freeze({
  region: 'ca-central-1',
  roleArn: 'arn:aws:iam::402010193138:role/TechlongSandboxBuyerWebPublisherRole',
  bucket: 'techlong-sandbox-buyer-web-402010193138-ca-central-1-v1',
  apiOrigin: 'https://first-acceptance.sandbox.techlong.cloud',
  retiredDistributionId: 'ERQVWHE0LMAMX',
});

function requireText(env, key) {
  const value = env[key];
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`SANDBOX_${key}_REQUIRED`);
  }
  if (value !== value.trim() || /[\r\n\0]/.test(value)) {
    throw new Error(`SANDBOX_${key}_FORMAT`);
  }
  return value;
}

// Pure validation only: no network, AWS SDK, secret loader or .env reader.
export function validateSandboxConfiguration(env) {
  const values = Object.fromEntries([
    'CLIENT_ID', 'HMAC_SECRET_KEY', 'BUYER_FIREBASE_WEB_VAPID_KEY',
    'BUYER_API_BASE_URL', 'AWS_ROLE_ARN', 'AWS_REGION', 'S3_BUCKET',
    'CLOUDFRONT_DISTRIBUTION_ID',
  ].map(key => [key, requireText(env, key)]));
  if (values.CLIENT_ID.length < 5 || values.CLIENT_ID.length > 200) {
    throw new Error('SANDBOX_CLIENT_ID_FORMAT');
  }
  if (values.HMAC_SECRET_KEY.length < 5 || values.HMAC_SECRET_KEY.length > 16384) {
    throw new Error('SANDBOX_HMAC_SECRET_KEY_FORMAT');
  }
  if (!/^[A-Za-z0-9_-]{87}$/.test(values.BUYER_FIREBASE_WEB_VAPID_KEY)) {
    throw new Error('SANDBOX_VAPID_PUBLIC_KEY_FORMAT');
  }
  if (values.AWS_ROLE_ARN !== SANDBOX_BINDING.roleArn ||
      values.AWS_REGION !== SANDBOX_BINDING.region ||
      values.S3_BUCKET !== SANDBOX_BINDING.bucket ||
      values.BUYER_API_BASE_URL !== SANDBOX_BINDING.apiOrigin) {
    throw new Error('SANDBOX_TARGET_BINDING_MISMATCH');
  }
  if (!/^[A-Z0-9]{5,30}$/.test(values.CLOUDFRONT_DISTRIBUTION_ID) ||
      values.CLOUDFRONT_DISTRIBUTION_ID === SANDBOX_BINDING.retiredDistributionId) {
    throw new Error('SANDBOX_DISTRIBUTION_BINDING_REQUIRED');
  }
  // The exact newly created distribution still needs independent stack-output
  // binding and human approval; syntax validation does not prove it exists.
  return {
    region: values.AWS_REGION,
    roleArn: values.AWS_ROLE_ARN,
    bucket: values.S3_BUCKET,
    apiOrigin: values.BUYER_API_BASE_URL,
    distributionId: values.CLOUDFRONT_DISTRIBUTION_ID,
  };
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  try {
    validateSandboxConfiguration(process.env);
    console.log('Sandbox configuration validated; resource existence and approval still required.');
  } catch (error) {
    // Error codes only: never echo supplied configuration or secret values.
    console.error(/^[A-Z0-9_]+$/.test(error.message) ? error.message : 'SANDBOX_CONFIGURATION_INVALID');
    process.exitCode = 1;
  }
}
