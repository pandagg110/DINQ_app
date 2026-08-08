# Android update builds

Set the public GitHub OAuth Client ID before any release build:

```bash
export GITHUB_CLIENT_ID=<production-github-oauth-client-id>
```

Do not put `GITHUB_CLIENT_SECRET` in the client build. The gateway exchanges the
one-time authorization code with the secret stored in its deployment environment.

The official APK is the default channel:

```bash
flutter build apk --release \
  --dart-define=GATEWAY_URL=https://api.dinq.me \
  --dart-define=APP_URL=https://dinq.me \
  --dart-define=GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
```

Build the Google Play bundle with an explicit channel:

```bash
flutter build appbundle --release \
  --dart-define=DISTRIBUTION_CHANNEL=google_play \
  --dart-define=GATEWAY_URL=https://api.dinq.me \
  --dart-define=APP_URL=https://dinq.me \
  --dart-define=GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
```

iOS release builds require the same OAuth configuration:

```bash
flutter build ipa --release \
  --dart-define=DISTRIBUTION_CHANNEL=app_store \
  --dart-define=GATEWAY_URL=https://api.dinq.me \
  --dart-define=APP_URL=https://dinq.me \
  --dart-define=GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
```

The same channel define also selects the subscription provider:

- `official_apk`: Stripe checkout for all four Web/APK plans.
- `google_play`: Google Play Billing for Basic monthly, Basic yearly, and Pro monthly. Pro yearly is unavailable.
- `app_store`: Apple StoreKit billing and the iOS App Store update channel.

Do not upload a bundle built without `DISTRIBUTION_CHANNEL=google_play` to Play Console. It would route subscription purchases to the official APK checkout path.

The app checks `GET /api/v1/app/version` on startup and whenever it returns to the foreground:

```http
GET /api/v1/app/version?platform=android&channel=official_apk&version_code=15
```

The iOS App Store build uses the same endpoint with its own platform and channel:

```http
GET /api/v1/app/version?platform=ios&channel=app_store&version_code=16
```

The request parameters come from the running build:

- `platform`: `android`
- `channel`: `official_apk` for direct APK builds, `google_play` for Play builds
- `version_code`: the installed Android build number

For iOS, `version_code` is the installed `CFBundleVersion`. The backend must
return the App Store product URL in `download_url`; iOS never falls back to the
Android APK endpoint.

Response `data` shape:

```json
{
  "platform": "android",
  "channel": "official_apk",
  "update_type": "force",
  "latest_version": "1.0.2",
  "latest_version_code": 16,
  "minimum_version": "1.0.2",
  "minimum_version_code": 16,
  "release_notes": "修复已知问题",
  "download_url": "https://assets.dinq.me/xxx.apk"
}
```

The backend owns version comparison. The client only follows `update_type`:

- `force`: blocking prompt with no Skip and no back dismissal
- `optional`: prompt with Skip
- `none` (or an unknown value): no prompt

The update button opens `download_url`. If it is missing, the client falls back to
`GET https://api.dinq.me/api/v1/app/download/android`.

The app does not call `/api/v1/app/releases/latest`; that endpoint is reserved for
the website's published APK metadata.

The update endpoint fails open, so an unavailable backend does not lock users out.
After opening the download page, the forced gate remains and checks again when the app resumes.
