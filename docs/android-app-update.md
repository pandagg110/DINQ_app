# Android update builds

The official APK is the default channel:

```bash
flutter build apk --release --dart-define=GATEWAY_URL=https://testapi.dinq.me
```

Build the Google Play bundle with an explicit channel:

```bash
flutter build appbundle --release \
  --dart-define=DISTRIBUTION_CHANNEL=google_play \
  --dart-define=GATEWAY_URL=https://api.dinq.me
```

The app checks `GET /api/v1/app/version` on startup and whenever it returns to the foreground.

- Official APK optional update: DINQ prompt with Later and Update now.
- Official APK forced update: blocking DINQ prompt.
- Google Play optional update: no DINQ prompt; Play handles ordinary updates.
- Google Play forced update: blocking prompt whose action opens the Play listing.

The update endpoint fails open, so an unavailable backend does not lock users out. After opening the download/store page, the forced gate remains and checks again when the app resumes.
