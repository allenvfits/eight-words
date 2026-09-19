# Eight Words — App Store Submission Handoff

## What is ready in the repository

- Native SwiftUI app for iPhone and iPad
- Eight free words per day across three difficulty levels and 3,000+ extended offline words
- Spoken pronunciation, syllable guide, saved words, and a saved-word review screen
- Up to six private on-device learner profiles, quizzes, tests, points, streaks, and in-app rewards
- StoreKit 2 purchase, restore, verified transaction, and entitlement handling
- Opaque 1024 × 1024 App Store icon
- Privacy manifest for on-device `UserDefaults` use
- Supabase-backed read-only vocabulary updates with bundled and cached offline fallbacks
- Public privacy and support pages in `docs/`
- GitHub Actions for unsigned iOS Simulator builds and GitHub Pages deployment

## Account-holder setup still required

### 1. Bundle ID

The project uses `com.allenvfits.eightwords`. Register that exact identifier in the Apple Developer account, or replace it consistently before archiving.

### 2. Apple development team

Select the correct Apple Developer team in Xcode under **Signing & Capabilities**. Team credentials and signing certificates should stay out of GitHub.

### 3. Windows-only TestFlight upload

The manually triggered `.github/workflows/testflight.yml` workflow archives and uploads the app on a GitHub-hosted Mac. Create a protected GitHub environment named `testflight` and add these environment secrets:

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_P8_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64`
- `IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`
- `IOS_APP_STORE_PROFILE_BASE64`

The Base64 values must be single-line encodings of the `.p8`, Apple Distribution `.p12`, and App Store `.mobileprovision` files. Never commit those files or values. After the matching app record, bundle ID, certificate, and profile exist, run **Actions > Upload to TestFlight > Run workflow**. The workflow validates the signed IPA before uploading it and uses the GitHub run number as the unique build number.

## Suggested App Store Connect metadata

- **Name:** Eight Words
- **Subtitle:** A little smarter every day
- **Primary category:** Education
- **Secondary category:** Reference
- **Age rating:** Complete the questionnaire truthfully; the current content is designed to qualify for a broad audience. Do not select the Kids Category unless the product is intentionally redesigned for its additional rules.
- **Privacy Policy URL:** `https://allenvfits.github.io/eight-words/privacy/`
- **Support URL:** `https://allenvfits.github.io/eight-words/support/`
- **Marketing URL:** `https://allenvfits.github.io/eight-words/`
- **App privacy:** Learning progress and saved words stay on-device. The current release has no Supabase credentials and uses its bundled catalog, so use the offline no-data-collected profile in [`APP-PRIVACY-DISCLOSURE.md`](APP-PRIVACY-DISCLOSURE.md).

### Promotional text

Learn eight useful words a day with clear definitions, natural examples, spoken pronunciation, and three levels for curious minds.

### Description

Build a stronger vocabulary one useful word at a time. Choose your level, read a clear definition, hear the pronunciation, split the word into syllables, and see it used in a natural sentence.

Explore more than 3,000 words, take quizzes and tests, earn points, unlock in-app rewards, and keep progress separate with private learner profiles. Eight Words gives you eight free words each day with no online account, no ads, and no clutter. Eight Words Plus removes the daily cap for the localized monthly price shown before purchase.

Privacy Policy: https://allenvfits.github.io/eight-words/privacy/

Terms of Use: https://allenvfits.github.io/eight-words/terms/

### Keywords

`vocabulary,words,dictionary,learning,education,spelling,pronunciation,daily,language,quiz`

## Review notes draft

Eight Words does not require an online account. Learner profiles, daily progress, selected difficulty, learned and saved words, quiz/test activity, points, streaks, and rewards remain on the device. This release uses its bundled vocabulary catalog and does not have Supabase credentials. Tap through eight words to display the Plus purchase screen. The first paywall tap loads and displays Apple’s localized product information; a separate tap starts purchase. Use Restore Purchases to test entitlement restoration. The app uses StoreKit 2 for all digital purchases.

## App Store Connect steps that require the account holder

1. Confirm Apple Developer Program membership is active.
2. Register `com.allenvfits.eightwords`, or update the project to another identifier you own.
3. Select the development team in Xcode and verify automatic signing.
4. Create the app record in App Store Connect.
5. Create the subscription group and product `com.allenvfits.eightwords.plus.monthly`, add localization, `$1.99` US pricing, availability, and the required review screenshot.
6. Archive a Release build on macOS, run **Validate App**, and upload it.
7. Add iPhone and iPad screenshots, privacy answers, age rating, contact details, and review notes.
8. Test the uploaded build with TestFlight before submitting it for App Review.

The first auto-renewable subscription must be submitted with the app version. Confirm the subscription display name, description, one-month duration, localized price, availability, review screenshot, and review notes are complete before submission.

## App privacy label gate

The Xcode privacy manifest does not generate the App Store privacy label. An Account Holder, Admin, or App Manager must separately publish the answers under **App Store Connect > App > App Privacy**. For the current offline release, publish **No, we do not collect data from this app**. Reassess the manifest, policy, and privacy label before enabling a backend.

## Share the beta before App Store release

1. Create the app record and final bundle ID in App Store Connect.
2. In Xcode, select the Apple Developer team, archive a Release build, and choose **Distribute App > App Store Connect > Upload**.
3. After Apple finishes processing the build, open the app's **TestFlight** tab.
4. For your own team, create an Internal Testing group and add App Store Connect users. Internal testing is the fastest path.
5. For friends or customers, first create an internal group, then create an External Testing group, add the build, complete **What to Test** and beta review contact information, and submit the build for TestFlight App Review.
6. After beta approval, create a public invitation link (with a tester limit) or invite people by email. Testers install Apple's TestFlight app and open the invitation.

The app is not publicly listed in the App Store during TestFlight testing. Apple currently allows up to 100 internal testers and up to 10,000 external testers; each beta build is available for 90 days.
