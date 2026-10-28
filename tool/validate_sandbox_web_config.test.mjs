import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {SANDBOX_BINDING, validateSandboxConfiguration} from './validate_sandbox_web_config.mjs';

function fixture() {
  return {
    CLIENT_ID: 'synthetic-ci-client',
    HMAC_SECRET_KEY: 'synthetic-ci-hmac-not-a-real-secret',
    BUYER_FIREBASE_WEB_VAPID_KEY: 'B' + 'a'.repeat(86),
    BUYER_API_BASE_URL: SANDBOX_BINDING.apiOrigin,
    AWS_ROLE_ARN: SANDBOX_BINDING.roleArn,
    AWS_REGION: SANDBOX_BINDING.region,
    S3_BUCKET: SANDBOX_BINDING.bucket,
    CLOUDFRONT_DISTRIBUTION_ID: 'ENEWTESTDISTRIBUTION',
  };
}

test('validates a synthetic sandbox configuration without returning private fields', () => {
  const result = validateSandboxConfiguration(fixture());
  assert.equal(result.bucket, SANDBOX_BINDING.bucket);
  assert.equal(result.apiOrigin, SANDBOX_BINDING.apiOrigin);
  assert.equal(result.HMAC_SECRET_KEY, undefined);
  assert.equal(result.CLIENT_ID, undefined);
});

for (const key of Object.keys(fixture())) {
  test(`rejects missing ${key}`, () => {
    const env = fixture(); delete env[key];
    assert.throws(() => validateSandboxConfiguration(env), {message: `SANDBOX_${key}_REQUIRED`});
  });
}

for (const [key, value] of [
  ['AWS_ROLE_ARN', 'arn:aws:iam::402010193138:role/SpeedFeastBuyerWebDeployRole'],
  ['AWS_REGION', 'us-east-1'],
  ['S3_BUCKET', 'speedfeast-buyer-web-402010193138-ca-central-1-an'],
  ['BUYER_API_BASE_URL', 'https://api.techlong.cloud'],
  ['BUYER_API_BASE_URL', SANDBOX_BINDING.apiOrigin + '/api'],
  ['BUYER_API_BASE_URL', SANDBOX_BINDING.apiOrigin + '?debug=true'],
]) {
  test(`refuses a different sandbox target: ${key} / ${value}`, () => {
    assert.throws(() => validateSandboxConfiguration({...fixture(), [key]: value}),
      {message: 'SANDBOX_TARGET_BINDING_MISMATCH'});
  });
}

test('refuses the retired distribution and malformed distribution identifiers', () => {
  for (const id of [SANDBOX_BINDING.retiredDistributionId, 'bad/id', 'https://example.invalid']) {
    assert.throws(() => validateSandboxConfiguration({...fixture(), CLOUDFRONT_DISTRIBUTION_ID: id}),
      {message: 'SANDBOX_DISTRIBUTION_BINDING_REQUIRED'});
  }
});

test('refuses whitespace, line breaks and malformed public configuration', () => {
  assert.throws(() => validateSandboxConfiguration({...fixture(), HMAC_SECRET_KEY: ' embedded\nvalue'}),
    {message: 'SANDBOX_HMAC_SECRET_KEY_FORMAT'});
  assert.throws(() => validateSandboxConfiguration({...fixture(), BUYER_FIREBASE_WEB_VAPID_KEY: 'missing'}),
    {message: 'SANDBOX_VAPID_PUBLIC_KEY_FORMAT'});
});

test('CLI failure never echoes supplied values', () => {
  const secret = 'synthetic-value-must-not-appear';
  const file = fileURLToPath(new URL('./validate_sandbox_web_config.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [file], {
    env: {...process.env, ...fixture(), HMAC_SECRET_KEY: secret, S3_BUCKET: 'unapproved-bucket'},
    encoding: 'utf8', windowsHide: true,
  });
  assert.equal(result.status, 1);
  assert.equal(result.stdout, '');
  assert.equal(result.stderr.trim(), 'SANDBOX_TARGET_BINDING_MISMATCH');
  assert.ok(!result.stderr.includes(secret));
});

const workflow = readFileSync(new URL('../.github/workflows/web-deploy.yml', import.meta.url), 'utf8').replaceAll('\r\n', '\n');
const step = name => {
  const marker = '      - name: ' + name + '\n';
  const start = workflow.indexOf(marker);
  assert.ok(start >= 0, `missing step ${name}`);
  const end = workflow.indexOf('      - name:', start + marker.length);
  return workflow.slice(start, end < 0 ? undefined : end);
};

test('push/PR verification has no AWS identity, production secrets or dispatch', () => {
  const verify = workflow.split('  verify:\n')[1].split('  deploy:\n')[0];
  assert.ok(verify.includes("if: github.event_name != 'workflow_dispatch'"));
  assert.ok(verify.includes('node --test tool/validate_sandbox_web_config.test.mjs'));
  assert.ok(verify.includes('https://api.example.invalid'));
  assert.ok(!/configure-aws-credentials|id-token:|secrets\.|gh workflow run|workflow_dispatch:/.test(verify));
  assert.ok(workflow.includes('  contents: read\n'));
});

test('explicit sandbox selects the protected environment and keeps production default', () => {
  assert.ok(workflow.includes('default: production\n'));
  assert.ok(workflow.includes('          - production\n          - sandbox\n'));
  assert.ok(workflow.includes("environment: ${{ inputs.target == 'sandbox' && 'techlong-sandbox-buyer-deploy' || 'production' }}"));
  assert.ok(step('Validate deployment target').includes('production|sandbox)'));
  assert.ok(workflow.includes("cancel-in-progress: ${{ inputs.target != 'sandbox' }}"));
});

test('sandbox secret is mandatory and shared build selects its name without value fallback', () => {
  const validation = step('Validate sandbox configuration');
  assert.ok(validation.includes("if: inputs.target == 'sandbox'"));
  assert.ok(validation.includes('${{ secrets.SANDBOX_BUYER_HMAC_SECRET_KEY }}'));
  assert.ok(!validation.includes('secrets.BUYER_HMAC_SECRET_KEY'));
  assert.ok(step('Build web release').includes("${{ secrets[inputs.target == 'sandbox' && 'SANDBOX_BUYER_HMAC_SECRET_KEY' || 'BUYER_HMAC_SECRET_KEY'] }}"));
  assert.ok(!/secrets\.SANDBOX_BUYER_HMAC_SECRET_KEY\s*\|\|/.test(workflow));
});

test('sandbox account/session scope and no-delete upload are kept distinct from production', () => {
  const auth = step('Authenticate sandbox to AWS');
  assert.ok(auth.includes("if: inputs.target == 'sandbox'"));
  assert.ok(auth.includes("allowed-account-ids: '402010193138'"));
  assert.ok(auth.includes('role-duration-seconds: 900'));
  assert.ok(auth.includes('disable-retry: true'));
  const upload = step('Deploy sandbox to S3 without deletion');
  assert.ok(upload.includes("if: inputs.target == 'sandbox'"));
  assert.ok(upload.includes("AWS_MAX_ATTEMPTS: '1'"));
  assert.ok(!upload.includes('--delete'));
  assert.ok(step('Deploy to S3').includes("if: inputs.target != 'sandbox'"));
  assert.ok(step('Deploy to S3').includes('aws s3 sync build/web "s3://${{ vars.S3_BUCKET }}" --delete'));
  assert.ok(step('Invalidate sandbox CloudFront cache').includes("AWS_MAX_ATTEMPTS: '1'"));
});

test('configuration is validated and the build completes before sandbox AWS authentication', () => {
  assert.ok(workflow.indexOf('- name: Validate sandbox configuration') < workflow.indexOf('- name: Build web release'));
  assert.ok(workflow.indexOf('- name: Build web release') < workflow.indexOf('- name: Authenticate sandbox to AWS'));
});
