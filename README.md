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

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
