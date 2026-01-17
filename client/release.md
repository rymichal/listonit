# Building for Release

## Prerequisites

```bash
cd client/listonit
```

Ensure `.env` is configured with the production API:
```
API_BASE_URL=https://api.manyhappyapples.com
```

## Android

**Build APK:**
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

**Build App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

## iOS

**Build:**
```bash
flutter build ios --release
```

Then open Xcode to archive and distribute.

## Testing Release Mode

Run on a connected device in release mode:
```bash
flutter run --release
```

## Notes

- Release builds suppress debug error screens
- Release builds are optimized and minified
- Debug prints are stripped in release mode
