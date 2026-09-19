# Eight Words — App Store Submission Handoff

## What is ready in the repository

- Native SwiftUI app for iPhone and iPad
- Eight free words per day across three difficulty levels
- Spoken pronunciation, syllable guide, saved words, and a saved-word review screen
- StoreKit 2 purchase, restore, verified transaction, and entitlement handling
- Opaque 1024 × 1024 App Store icon
- Privacy manifest for on-device `UserDefaults` use
- Public privacy and support pages in `docs/`
- GitHub Actions for unsigned iOS Simulator builds and GitHub Pages deployment

## Decisions needed before creating the App Store product

### 1. Paid product model

The code currently uses an auto-renewable `$1.99/month` subscription with product ID `com.eightwords.plus.monthly`. The native library currently contains 60 unique hand-written entries. Before review, choose one of these paths:

- **Subscription:** add a much larger library and a credible schedule of new content so Plus provides ongoing value.
- **One-time unlock:** replace the monthly subscription with a non-consumable lifetime unlock. This is the faster fit for a fixed offline library.

Do not submit the current 60-word fixed library as “unlimited” recurring value without resolving this decision.

### 2. Final bundle ID

The project currently uses the placeholder `com.eightwords.app`. Create a unique identifier in the Apple Developer account, then update both Debug and Release build settings before archiving.

### 3. Apple development team

Select the correct Apple Developer team in Xcode under **Signing & Capabilities**. Team credentials and signing certificates should stay out of GitHub.

## Suggested App Store Connect metadata

- **Name:** Eight Words
- **Subtitle:** A little smarter every day
- **Primary category:** Education
- **Secondary category:** Reference
- **Age rating:** Complete the questionnaire truthfully; the current content is designed to qualify for a broad audience. Do not select the Kids Category unless the product is intentionally redesigned for its additional rules.
- **Privacy Policy URL:** `https://allenvfits.github.io/eight-words/privacy/`
- **Support URL:** `https://allenvfits.github.io/eight-words/support/`
- **Marketing URL:** `https://allenvfits.github.io/eight-words/`
- **App privacy:** The current build does not transmit user data off device. Confirm this answer again if analytics, accounts, crash reporting, or a remote dictionary are added.

### Promotional text

Learn eight useful words a day with clear definitions, natural examples, spoken pronunciation, and three levels for curious minds.

### Description

Build a stronger vocabulary one useful word at a time. Choose your level, read a clear definition, hear the pronunciation, split the word into syllables, and see it used in a natural sentence.

Eight Words gives you eight free words each day with no account, no ads, and no clutter. Save favorites for review and move between Everyday, Growing, and Curious whenever you like.

### Keywords

`vocabulary,words,dictionary,learning,education,spelling,pronunciation,daily,language,quiz`

## Review notes draft

Eight Words does not require an account and does not collect or transmit personal data. Daily progress, selected difficulty, and saved words remain on the device. Tap through eight words to display the Plus purchase screen. Use the Restore Purchases button to test entitlement restoration. The app uses Apple StoreKit for all digital purchases.

Update these notes if the paid product model changes.

## App Store Connect steps that require the account holder

1. Confirm Apple Developer Program membership is active.
2. Register the final bundle ID.
3. Select the development team in Xcode and verify automatic signing.
4. Create the app record in App Store Connect.
5. Resolve the paid product decision above.
6. If keeping the subscription, create the subscription group and matching product, add localization, pricing, and the required review screenshot.
7. Archive a Release build on macOS, run **Validate App**, and upload it.
8. Add iPhone and iPad screenshots, privacy answers, age rating, contact details, and review notes.
9. Test the uploaded build with TestFlight before submitting it for App Review.
