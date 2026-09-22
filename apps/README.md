# Native shells

Both apps load `https://vancouvervice.heyitsmejosh.com/play.html` and show a local
Vancouver Vice splash while connecting. Android offers a retry on load failure;
desktop shows a connection error. Launcher and installer icons come from
`site/icon.png` (256 px source, resized for platform packaging).

## Android

Use JDK 17, Android SDK 34 and Gradle 8.9. Set `ANDROID_HOME` to your SDK.
Run from `apps/android`:

```sh
gradle assembleDebug lintDebug
cp keystore.properties.example keystore.properties
# Replace every placeholder and supply your release keystore.
gradle assembleRelease bundleRelease
```

`keystore.properties` and keystores are ignored by Git. A release build requires
the configured key; it never falls back to the debug key. CI uses a base64
`ANDROID_KEYSTORE_BASE64` secret plus `ANDROID_STORE_PASSWORD`,
`ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`.

## Desktop

Run `node tests/native.mjs` from the repository root to check startup, network
failure, and cancelling startup.

Run from `apps/desktop`:

```sh
npm install
npm run dist          # local package; signing optional
npm run dist:signed   # Windows/macOS release; signing required
```

Export the variables in `.env.example` with real values before a signed build.
The example file is documentation, not automatically loaded. Windows uses
`WIN_CSC_LINK` and `WIN_CSC_KEY_PASSWORD`. macOS uses `CSC_LINK` and
`CSC_KEY_PASSWORD`, with `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, and
`APPLE_TEAM_ID` for notarization. Missing signing keys fail the signed build.
Linux AppImage/deb builds use `dist`; these formats do not use Apple or Windows
code-signing certificates.

The release workflow expects the same names as repository secrets and builds
signed Windows/macOS installers and an Android release APK/AAB. It publishes
only tag builds. Configure secrets before running it.

See [Android signing](https://developer.android.com/studio/publish/app-signing)
and [electron-builder signing](https://www.electron.build/code-signing.html).
