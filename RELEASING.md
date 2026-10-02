# Releasing Red Box

Version: **1.0.0+1**. Android application ID and iOS bundle ID: **com.sutechs.redbox**. Support: **redbox@sutechs.com**.

## Web and GitHub

- Public repository: https://github.com/SuTechs/redbox
- Browser game: https://sutechs.github.io/redbox/
- Privacy policy: https://sutechs.com/privacy
- Terms: https://sutechs.com/terms
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

The Play Console app record and English listing are created. The icon, feature graphic, and six marketing screenshots are uploaded in filename order and declared as created or edited using AI. Privacy, unrestricted app access, no ads, all age groups, content ratings, no data collection/sharing, no advertising ID, and the government/financial/health declarations are saved. IARC assigned Everyone in North America and PEGI 3 in Europe.

Version **1.0.0 (1)** is available to the existing six-person **Sutechs Alpha Testers** list on the active internal-testing track. The bundle is accepted with API 24+ support and target SDK 36.

On **October 3, 2026**, the same bundle, listing, and declarations were submitted for a full production rollout. Play Console shows **Changes in review**, with automated checks running before review. Managed publishing is off, so approved changes publish automatically. Availability targets 175 countries/regions plus Rest of World, excluding China and Vietnam. Store approval is not guaranteed by a successful local build, and the production app is not publicly launched yet.

The Android build targets API **36** and supports API **24+**. Google requires API 36 for new phone app submissions from August 31, 2026. New personal accounts created after November 13, 2023 may need a closed test with 12 opted-in testers for 14 continuous days before applying for production access. Verify the account’s own dashboard requirements.

Official references: [target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en), [preview asset specifications](https://support.google.com/googleplay/android-developer/answer/9866151), [testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en), [16 KB page-size support](https://developer.android.com/guide/practices/page-sizes).

## App Store — submitted for review

The iOS app record is created as **Red Box: A Little Reset** with SKU `sutechs-redbox-ios`. The English description, subtitle, promotional text, keywords, support/marketing URLs, review instructions, and private review contact are saved in App Store Connect. The app is categorized as Games → Puzzle / Casual, rated 4+, and uses Apple's standard EULA. App Privacy is published as **Data Not Collected**, with the canonical SuTechs privacy URL. The app is free and uses automatic release after approval.

Six iPhone screenshots at **1320×2868** and six iPad screenshots at **2064×2752** are uploaded in filename order. They are marketing compositions around actual Flutter captures with iOS layout and safe areas, rather than resized Android captures. Copy and exports live in `store/app-store/`; contact sheets are `docs/store-preview-iphone.jpg` and `docs/store-preview-ipad.jpg`.

The signed archive exported successfully, and **1.0.0 (1)** was uploaded, processed, and attached to the App Store version. The local IPA is `build/ios/ipa/redbox.ipa`. Signing/export/upload logs and account-specific export options stay in ignored `release-private/`. Team selection is supplied locally rather than committed to the Xcode project. The app includes local-font notices and the shared-preferences required-API privacy manifest.

On **October 3, 2026**, version **1.0.0 (1)** was submitted to App Review and shows **Waiting for Review**. The **Red Box Testers** internal TestFlight group contains the build with status **Testing**, and the existing eligible App Store Connect user has been invited. New builds are added to the group manually.

Launch availability is set for **173 regions**, excluding mainland China and Vietnam pending the required game licensing documents. Apple's [regional requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) describe those documents. Neither native store is publicly launched yet.

## Regenerate the visuals

```sh
# Pillow is needed by the Python export tools.
python3 -m pip install Pillow
python3 tools/export_brand.py
flutter test tools/capture_screenshots_test.dart
python3 tools/render_store_assets.py
# Native iOS layouts and matching marketing exports:
flutter test tools/capture_screenshots_test.dart --dart-define=SCREENSHOT_DEVICE=iphone
python3 tools/render_store_assets.py --device iphone
flutter test tools/capture_screenshots_test.dart --dart-define=SCREENSHOT_DEVICE=ipad
python3 tools/render_store_assets.py --device ipad
```

Brand source and the image-generation prompt are in `assets/brand/`. Design reference and gameplay specification remain in `DESIGN.md` and `product.md`.
