# speedfeast

SpeedFeast for Client

## Credits
- ChatGPT (AI assistant, OpenAI)

## Getting Started

The API origin is required for every local run and build. Pass it through the
same compile-time setting used by the production workflow:

```powershell
flutter run -d chrome --dart-define=BUYER_API_BASE_URL=http://localhost:3000
```

Replace the value with the HTTP(S) origin for the target environment. Do not
include a path or trailing slash. Production uses
`https://api.techlong.cloud` through the GitHub Actions variable.

## Web deployment targets

Pushes and pull requests run analysis, tests, deployment-contract checks and a
Web build with synthetic settings; they do not assume an AWS role or publish.
The existing manual Web workflow now has an explicit `target` choice:

- `production` retains the legacy configuration and upload behavior (including
  its existing deletion flag). It remains the default for compatibility.
- `sandbox` uses `techlong-sandbox-buyer-deploy`, the distinct
  `SANDBOX_BUYER_HMAC_SECRET_KEY`, and uploads without deleting existing objects.
  Missing sandbox configuration fails before AWS authentication; there is no
  production-secret fallback. Account, role, region, bucket and API are checked
  by `tool/validate_sandbox_web_config.mjs`.

The sandbox environment, its human reviewer, exact CloudFront output binding,
AWS resources, CORS change and private input provisioning require separate
approval and installation. This code does not create them or prove they are
ready. Do not dispatch either target without the reviewed resource scope.
The sandbox session requests 900 seconds, does not cancel an in-progress run,
and disables AWS authentication/CLI provider retries. Unknown outcomes are not
an instruction to re-run the workflow.

As in the existing client design, a HMAC provided through `--dart-define` becomes
part of the public Web build. A GitHub Secret input does not keep that value
secret from people who can read the resulting JavaScript. Do not commit private
input values or log them.

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
