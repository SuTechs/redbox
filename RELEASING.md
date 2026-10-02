# Releasing Red Box

Version: **1.0.0+1**. Android application ID and iOS bundle ID: **com.sutechs.redbox**. Support: **redbox@sutechs.com**.

## Web and GitHub

- Public repository: https://github.com/SuTechs/redbox
- Browser game: https://sutechs.github.io/redbox/
- Privacy policy: https://sutechs.github.io/redbox/privacy.html
- Support page: https://sutechs.github.io/redbox/support.html

Enable GitHub Pages with the **GitHub Actions** source. `.github/workflows/pages.yml` checks formatting, analysis, and tests, builds with `/redbox/` as the base path, and deploys on pushes to `main`. Flutter and CanvasKit resources are bundled into the deployment. Browser audio begins after a player interaction.

## Android signing

The local `android/key.properties` references the existing upload keystore. It is ignored, as are keystores and service account files. Do not publish the configuration or private key. Release builds require all signing fields and reject the standard Android debug alias.

For a new checkout, copy `android/key.properties.example` to `android/key.properties`, supply the existing upload key configuration locally, and keep the key backed up. `storeFile` is resolved relative to `android/`, or it can be an absolute path. Environment variables override file values:

- `REDBOX_STORE_FILE`
- `REDBOX_STORE_PASSWORD`
- `REDBOX_KEY_ALIAS`
- `REDBOX_KEY_PASSWORD`

```sh
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
flutter build apk --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console. The APK is suitable for direct device testing. Increment the build number in `pubspec.yaml` for each new Play upload.

The manual Android workflow requires GitHub secrets `REDBOX_KEYSTORE_BASE64`, `REDBOX_STORE_PASSWORD`, `REDBOX_KEY_ALIAS`, and `REDBOX_KEY_PASSWORD`. It produces a short-lived private Actions artifact and does not automatically upload or publish a Play release. No signing secrets are required by the public Pages workflow.

## Google Play listing

The following assets are prepared under `store/google-play/`:

| Asset | File |
| --- | --- |
| Name | `title.txt` |
| Short description | `short-description.txt` |
| Full description | `full-description.txt` |
| Release notes | `release-notes.txt` |
| 512×512 icon | `icon.png` |
| 1024×500 feature graphic | `feature-graphic.png` |
| Six 1080×1920 marketing screenshots | `screenshots/01-*` through `06-*` |

Use the screenshot order in the filenames. Headlines introduce the experience; the framed interface comes from actual Flutter renders. `docs/store-preview.jpg` shows the whole set. Raw captures are preserved separately under `docs/screenshots/`.

Suggested category: **Game → Puzzle**. The current build has no advertisements, purchases, login, multiplayer, or user-generated content. Players do not need credentials for app review. The native app does not collect or share data; assess the Data safety form against this exact build and its pinned dependencies. Web hosting and support-email handling are described separately in the privacy policy.

Account steps remain in Play Console: create the app, confirm the intended target age groups and countries, complete the content-rating questionnaire and app-content declarations, register the app/signing certificate, upload the signed AAB, and run the required device and testing checks. Start with internal testing and the pre-launch report before requesting production release. Store approval is not guaranteed by a successful local build.

The Android build targets API **36** and supports API **24+**. Google requires API 36 for new phone app submissions from August 31, 2026. New personal accounts created after November 13, 2023 may need a closed test with 12 opted-in testers for 14 continuous days before applying for production access. Verify the account’s own dashboard requirements.

Official references: [target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [preview asset specifications](https://support.google.com/googleplay/android-developer/answer/9866151), [testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en), [16 KB page-size support](https://developer.android.com/guide/practices/page-sizes).

## App Store — coming soon

The iOS bundle ID and full icon set are prepared. The app includes the local-font notices; the shared-preferences plugin supplies its required-API privacy manifest. The simulator build verifies compilation, not device signing or App Store approval.

Before the iOS launch, select your Apple development team in Xcode, register `com.sutechs.redbox` in App Store Connect, test on real iPhones and iPads, create screenshots at Apple’s required device sizes, complete App Privacy and age-rating declarations, archive a signed build, and review the App Store listing. Google Play screenshot files are not a replacement for the required iOS device captures.

## Regenerate the visuals

```sh
# Pillow is needed by the Python export tools.
python3 -m pip install Pillow
python3 tools/export_brand.py
flutter test tools/capture_screenshots_test.dart
python3 tools/render_store_assets.py
```

Brand source and the image-generation prompt are in `assets/brand/`. Design reference and gameplay specification remain in `DESIGN.md` and `product.md`.
