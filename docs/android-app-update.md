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

The same channel define also selects the subscription provider:

- `official_apk`: Stripe checkout for all four Web/APK plans.
- `google_play`: Google Play Billing for Basic monthly, Basic yearly, and Pro monthly. Pro yearly is unavailable.

Do not upload a bundle built without `DISTRIBUTION_CHANNEL=google_play` to Play Console. It would route subscription purchases to the official APK checkout path.

The app checks `GET /api/v1/app/version` on startup and whenever it returns to the foreground.

- Official APK optional update: DINQ prompt with Later and Update now.
- Official APK forced update: blocking DINQ prompt.
- Google Play optional update: no DINQ prompt; Play handles ordinary updates.
- Google Play forced update: blocking prompt whose action opens the Play listing.

The update endpoint fails open, so an unavailable backend does not lock users out. After opening the download/store page, the forced gate remains and checks again when the app resumes.

The first update-enabled build is `0.1.1+6`. To force users of the previous `versionCode 5` development APK to upgrade, configure both `latest_version_code` and `minimum_version_code` as `6` for `official_apk`.
