# Eight Words — Codex Handoff

Last updated: September 19, 2026

## Goal

Prepare Eight Words for TestFlight and App Store review, add a secure Supabase-backed vocabulary catalog, and keep the app fully usable offline. The app is native SwiftUI for iPhone and iPad. A separate Render service is not required for the current architecture.

## Completed

- Fixed the daily counter's midnight rollover so a new day starts at word one without skipping.
- Added saved-word browsing, syllable display, speech, StoreKit 2 purchase/restore handling, and clearer paywall/legal links.
- Added an opaque 1024 × 1024 App Store icon and an Apple privacy manifest.
- Published privacy and support pages with GitHub Pages:
  - `https://allenvfits.github.io/eight-words/privacy/`
  - `https://allenvfits.github.io/eight-words/support/`
- Added a direct read-only Supabase Data API integration with:
  - publishable-key-only client configuration;
  - Row Level Security and a published/active-words SELECT policy;
  - 60 seeded words with stable IDs;
  - validation, pagination, a last-known-good cache, and bundled offline fallback;
  - no service-role or secret key in the app.
- Added an App Store privacy answer sheet in `APP-PRIVACY-DISCLOSURE.md` and aligned the privacy policy and manifest with the intended Supabase build.
- Added GitHub Actions checks for metadata, icon dimensions/alpha, privileged-key scanning, Debug Simulator build, unsigned Release device build, unit tests, and browser-preview JavaScript syntax.
- Expanded the iOS test suite to cover the word catalog, stable IDs, cache coding, Supabase request/decoding behavior, HTTPS legal links, daily rotation, the free-word limit/Plus bypass, saved-word persistence, and midnight rollover.
- Added App Store metadata, review notes, signing/upload steps, and TestFlight instructions to `APP-STORE-SUBMISSION.md`.
- Hardened the Plus paywall so checking the App Store price never starts a purchase, the localized product name is visible before purchase, Restore is disabled during StoreKit operations, and a granted transaction clears any earlier pending-approval message.

## Latest verification

- GitHub Actions run `35438248250` passed on commit `42a03bb`: metadata/StoreKit validation, privacy manifest, icon dimensions and alpha, privileged-key scan, Xcode 26.6 Debug Simulator build, unsigned optimized Release device build, all nine unit tests, and the web JavaScript check.
- GitHub Pages run `35438191375` passed after the privacy-policy update, and the public privacy/support URLs are deployed.
- The seed file contains the same 60 unique stable IDs as the bundled catalog.
- The app continues to work from bundled data when Supabase is absent or unreachable.

## Waiting on the owner

Do not guess or silently resolve these choices:

1. **Supabase cost:** a dedicated `eight-words` project in the existing Supabase organization is quoted at **$10/month**. It has not been created because explicit cost approval was not received. After approval, create it in a US West region, apply `supabase/schema.sql` and `supabase/seed.sql`, obtain only the project URL and publishable client key, configure both build configurations, run a live REST read, and run Supabase security/performance advisors.
2. **Paid product:** the code currently uses the auto-renewable product `com.eightwords.plus.monthly` at $1.99/month. With only 60 words, “unlimited” recurring value is a review risk. Recommended: change this to a $1.99 non-consumable lifetime unlock, or substantially grow and regularly update the catalog before keeping a subscription.
3. **Bundle ID:** `com.eightwords.app` is a placeholder. Recommended candidate: `com.allenvfits.eightwords`, but the owner must confirm it and register it in the Apple Developer account.
4. **Signing:** no `DEVELOPMENT_TEAM` belongs in GitHub. The owner must select the Apple Developer team locally in Xcode.
5. **Support contact:** the public support page currently links to GitHub Issues. Before submission, confirm a private support/privacy email address and add it to the support and privacy pages.

## Known App Review follow-ups

- Add StoreKitTest coverage or complete the equivalent Sandbox/TestFlight matrix for purchase, restore, pending approval, renewal, cancellation, expiration, and revocation.

## Important configuration state

- `SUPABASE_PROJECT_URL` is empty in Debug and Release.
- `SUPABASE_PUBLISHABLE_KEY` is empty in Debug and Release.
- This is intentional until the paid project is approved; the app falls back to bundled words.
- Never place an `sb_secret_...`, `service_role`, database password, or Supabase management token in the app or repository.
- `PrivacyInfo.xcprivacy` currently describes the intended Supabase-enabled production build. If an offline-only build is submitted, use the offline profile in `APP-PRIVACY-DISCLOSURE.md` and make the manifest match.

## Remaining release verification

After the owner decisions and live Supabase setup:

1. Verify live Supabase rows and RLS with the publishable key, then confirm the app still falls back correctly while offline.
2. Create the matching App Store Connect app and in-app purchase product.
3. Enter and publish the App Privacy answers from `APP-PRIVACY-DISCLOSURE.md`; the Xcode privacy manifest alone does not create the App Store privacy label.
4. Build a signed Release archive on a Mac, run Xcode **Validate App**, and upload it.
5. Test a fresh install, offline launch, word rollover, purchase, restore, expiration/revocation, privacy/support links, VoiceOver, large Dynamic Type, iPhone, and iPad in TestFlight.
6. Use an internal TestFlight group first. For friends, submit the build for external TestFlight review, then share a public invitation link or email invitations.

Only Apple can approve the app. Passing CI establishes build/test readiness, not App Store approval.
