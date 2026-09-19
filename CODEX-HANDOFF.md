# Eight Words — Codex Handoff

Last updated: September 19, 2026

## Goal

Prepare Eight Words for TestFlight and App Store review, add a secure Supabase-backed vocabulary catalog, and keep the app fully usable offline. The app is native SwiftUI for iPhone and iPad. A separate Render service is not required for the current architecture.

## Completed

- Fixed the daily counter's midnight rollover so a new day starts at word one without skipping.
- Added saved-word browsing, syllable display, speech, StoreKit 2 purchase/restore handling, and clearer paywall/legal links.
- Added an opaque 1024 × 1024 App Store icon and an Apple privacy manifest.
- Published privacy, support, terms, and attribution pages with GitHub Pages:
  - `https://allenvfits.github.io/eight-words/privacy/`
  - `https://allenvfits.github.io/eight-words/support/`
  - `https://allenvfits.github.io/eight-words/terms/`
  - `https://allenvfits.github.io/eight-words/attributions/`
- Added a direct read-only Supabase Data API integration with:
  - publishable-key-only client configuration;
  - Row Level Security and a published/active-words SELECT policy;
  - 60 seeded words with stable IDs;
  - validation, pagination, a last-known-good cache, and bundled offline fallback;
  - no service-role or secret key in the app.
- Added an App Store privacy answer sheet in `APP-PRIVACY-DISCLOSURE.md` and aligned the privacy policy and manifest with the current offline release.
- Added GitHub Actions checks for metadata, icon dimensions/alpha, privileged-key scanning, Debug Simulator build, unsigned Release device build, unit tests, and browser-preview JavaScript syntax.
- Expanded the iOS test suite to cover the word catalog, stable IDs, cache coding, Supabase request/decoding behavior, HTTPS legal links, daily rotation, the free-word limit/Plus bypass, saved-word persistence, and midnight rollover.
- Added App Store metadata, review notes, signing/upload steps, and TestFlight instructions to `APP-STORE-SUBMISSION.md`.
- Hardened the Plus paywall so checking the App Store price never starts a purchase, the localized product name is visible before purchase, Restore is disabled during StoreKit operations, and a granted transaction clears any earlier pending-approval message.
- Added a commercially usable, attributed catalog of 3,000 Open English WordNet entries plus 60 original curated entries. The catalog is bundled for offline use, while Supabase rows can update or extend it without shrinking the library.
- Added native five-question quizzes, ten-question tests, up to six private on-device learner profiles, separate progress, points, streaks, saved words, deterministic rewards, and working Sunshine/Galaxy themes.
- Replaced the browser preview's research-only candidate list with the same CC BY 4.0 catalog and removed the obsolete source list.
- Finalized the code-side identifiers as `com.allenvfits.eightwords` and `com.allenvfits.eightwords.plus.monthly`.

## Latest verification

- GitHub Actions run `35440379129` passed on commit `9b1951d`: catalog/StoreKit/privacy validation, icon dimensions and alpha, privileged-key scan, Xcode 26.6 Debug Simulator build, unsigned optimized Release device build with `WordCatalog.json`, all 12 unit tests, and both browser JavaScript syntax checks.
- GitHub Pages run `35440207459` passed on commit `f2bba82`; the homepage, privacy, support, terms, and attribution URLs all returned HTTP 200 after deployment.
- The 60-row optional Supabase seed updates matching curated entries while the 3,000-word extended catalog remains bundled.
- The app continues to work from bundled data when Supabase is absent or unreachable.

## Waiting on the owner

These actions require the owner's paid accounts or private information:

1. **Supabase is optional for version 1:** a dedicated hosted project was quoted at **$10/month** and was not created because no purchase was authorized. The app is complete and fully functional offline. If live updates are enabled later, create the project, apply `supabase/schema.sql` and `supabase/seed.sql`, configure only the project URL and publishable key, test a public REST read, and run Supabase security/performance advisors.
2. **Apple identifiers and product:** register `com.allenvfits.eightwords`, create the monthly product `com.allenvfits.eightwords.plus.monthly`, set the US price to $1.99, and complete its localization and review screenshot in App Store Connect.
3. **Signing:** no `DEVELOPMENT_TEAM` belongs in GitHub. The owner must select the Apple Developer team locally in Xcode.
4. **Support contact:** the public support page currently links to GitHub Issues. A private support/privacy email should be added before submission if the owner does not want customers using public issues.

## Known App Review follow-ups

- Add StoreKitTest coverage or complete the equivalent Sandbox/TestFlight matrix for purchase, restore, pending approval, renewal, cancellation, expiration, and revocation.

## Important configuration state

- `SUPABASE_PROJECT_URL` is empty in Debug and Release.
- `SUPABASE_PUBLISHABLE_KEY` is empty in Debug and Release.
- This is intentional until the paid project is approved; the app falls back to bundled words.
- Never place an `sb_secret_...`, `service_role`, database password, or Supabase management token in the app or repository.
- `PrivacyInfo.xcprivacy` declares no collected data for the current offline release and documents the required-reason API used for local preferences.

## Remaining release verification

1. Create the matching App Store Connect app and in-app purchase product.
2. Enter and publish the offline App Privacy answers from `APP-PRIVACY-DISCLOSURE.md`; the Xcode privacy manifest alone does not create the App Store privacy label.
3. Build a signed Release archive on a Mac, run Xcode **Validate App**, and upload it.
4. Test a fresh install, offline launch, profiles, quizzes/tests, rewards, word rollover, purchase, restore, expiration/revocation, legal links, VoiceOver, large Dynamic Type, iPhone, and iPad in TestFlight.
5. Use an internal TestFlight group first. For friends, submit the build for external TestFlight review, then share a public invitation link or email invitations.

Only Apple can approve the app. Passing CI establishes build/test readiness, not App Store approval.
