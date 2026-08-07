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
  --dart-define=GATEWAY_URL=https://api.dinq.me \
  --dart-define=APP_URL=https://dinq.me \
  --dart-define=GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID
```

The same channel define also selects the subscription provider:

- `official_apk`: Stripe checkout for all four Web/APK plans.
- `google_play`: Google Play Billing for Basic monthly, Basic yearly, and Pro monthly. Pro yearly is unavailable.

Do not upload a bundle built without `DISTRIBUTION_CHANNEL=google_play` to Play Console. It would route subscription purchases to the official APK checkout path.

The app checks `GET /api/v1/app/releases/latest` on startup and whenever it returns to the foreground.

Response `data` shape:

```json
{
  "release": {
    "version": "1.5.0",
    "version_code": 15,
    "release_notes": "更新说明",
    "file_url": "https://assets.dinq.me/...apk",
    "file_name": "dinq-1.5.0.apk",
    "file_size": 123456789,
    "published_at": "2026-08-06T10:00:00Z",
    "force_update": false
  },
  "stable_download_url": "/api/v1/app/download/android"
}
```

Client compares local `versionCode` with `release.version_code`:

- behind + `force_update=true`: blocking prompt (no Skip)
- behind + `force_update=false`: prompt with Skip (official_apk only)
- already up to date: no prompt

Update always opens the fixed download URL from `stable_download_url`
(`GET https://api.dinq.me/api/v1/app/download/android`). Release notes come from
`release.release_notes`.

The update endpoint fails open, so an unavailable backend does not lock users out.
After opening the download page, the forced gate remains and checks again when the app resumes.
