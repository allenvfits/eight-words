# Eight Words — App Store Submission Handoff

## What is ready in the repository

- Native SwiftUI app for iPhone and iPad
- Eight free words per day across three difficulty levels
- Spoken pronunciation, syllable guide, saved words, and a saved-word review screen
- StoreKit 2 purchase, restore, verified transaction, and entitlement handling
- Opaque 1024 × 1024 App Store icon
- Privacy manifest for on-device `UserDefaults` use
- Supabase-backed read-only vocabulary updates with bundled and cached offline fallbacks
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
- **App privacy:** Learning progress and saved words stay on-device. The production build contacts Supabase to download vocabulary, whose retained gateway logs require App Store privacy disclosures. Use the exact answer sheet in [`APP-PRIVACY-DISCLOSURE.md`](APP-PRIVACY-DISCLOSURE.md), then verify it against the live project's logging settings before publishing the label.

### Promotional text

Learn eight useful words a day with clear definitions, natural examples, spoken pronunciation, and three levels for curious minds.

### Description

Build a stronger vocabulary one useful word at a time. Choose your level, read a clear definition, hear the pronunciation, split the word into syllables, and see it used in a natural sentence.

Eight Words gives you eight free words each day with no account, no ads, and no clutter. Save favorites for review and move between Everyday, Growing, and Curious whenever you like.

### Keywords

`vocabulary,words,dictionary,learning,education,spelling,pronunciation,daily,language,quiz`

## Review notes draft

Eight Words does not require an account. Daily progress, selected difficulty, and saved words remain on the device. The app makes read-only requests to Supabase for published vocabulary and never sends learning activity in those requests. Tap through eight words to display the Plus purchase screen. Use the Restore Purchases button to test entitlement restoration. The app uses Apple StoreKit for all digital purchases.

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

## App privacy label gate

The Xcode privacy manifest does not generate the App Store privacy label. An Account Holder, Admin, or App Manager must separately publish the answers under **App Store Connect > App > App Privacy**. For the intended Supabase build, the prepared answer sheet conservatively declares Coarse Location, Product Interaction, and Other Diagnostic Data for App Functionality, linked to the user, and not used for tracking. If Supabase remains disabled in the uploaded build, use the offline-only profile instead.

## Share the beta before App Store release

1. Create the app record and final bundle ID in App Store Connect.
2. In Xcode, select the Apple Developer team, archive a Release build, and choose **Distribute App > App Store Connect > Upload**.
3. After Apple finishes processing the build, open the app's **TestFlight** tab.
4. For your own team, create an Internal Testing group and add App Store Connect users. Internal testing is the fastest path.
5. For friends or customers, first create an internal group, then create an External Testing group, add the build, complete **What to Test** and beta review contact information, and submit the build for TestFlight App Review.
6. After beta approval, create a public invitation link (with a tester limit) or invite people by email. Testers install Apple's TestFlight app and open the invitation.

The app is not publicly listed in the App Store during TestFlight testing. Apple currently allows up to 100 internal testers and up to 10,000 external testers; each beta build is available for 90 days.
