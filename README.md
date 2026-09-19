# Eightwise

Eightwise is a native SwiftUI vocabulary app for iPhone and iPad. It gives people a calm, age-inclusive way to learn words at three levels: **Everyday**, **Growing**, and **Curious**.

**Eight words. A little wiser.**

The repository also includes a Windows-friendly browser preview in `web/`. Both versions use the same 3,000-word extended offline catalog, clickable syllable guides, multiple local profiles, prominent difficulty controls, saved-word favorites, quizzes, ten-question tests, points, streaks, and redeemable in-app rewards.

## Run on Windows

Double-click `web/start-windows.bat`. It opens the browser preview at `http://127.0.0.1:8765`. Keep the command window open while using the app, then close it when finished.

The Windows preview stores profiles on that computer only. The recommended cloud account architecture and reward economy are documented in `web/ACCOUNTS-AND-REWARDS.md`.

## Included

- 60 hand-written entries plus 3,000 filtered Open English WordNet entries available offline
- Eight free words each calendar day, saved on-device
- Level switching at any time
- Spoken pronunciation using the system voice
- A StoreKit 2 monthly subscription flow for unlimited words
- A clear unlimited mode with no daily cap for `$1.99/month`
- Saved-word favorites with a dedicated review screen
- Five-question quizzes and ten-question tests
- Up to six private on-device learner profiles
- Points, streaks, deterministic in-app rewards, and redeemable visual themes
- Read-only Supabase vocabulary updates with bundled and last-known-good offline fallbacks
- Restore purchases and transaction verification
- Dynamic Type, VoiceOver labels, reduced-motion handling, and iPad support
- A local StoreKit testing configuration with a `$1.99/month` product
- An Apple privacy manifest declaring local preferences use and no collected data for the current offline release
- Public privacy and support pages published from `docs/`
- GitHub Actions checks for the iOS build, plists, app icon, and web JavaScript

## Run it

1. Open `EightWords.xcodeproj` in a current App Store-supported version of Xcode on macOS.
2. Choose the **EightWords** scheme and an iPhone simulator.
3. Build and run.

The shared scheme uses `EightWords.storekit`, so the paywall can be tested locally without creating an App Store Connect product first. Use **Debug > StoreKit > Manage Transactions** in Xcode to manage test purchases.

The app works from its bundled 3,000+ word catalog when Supabase is unavailable or not configured. Live setup instructions, read-only Row Level Security, and seed data are in [`supabase/`](supabase/README.md). Remote rows update or extend the bundled catalog instead of replacing it. A separate Render service is not required.

The extended catalog is a filtered and reformatted subset of Open English WordNet 2025 under CC BY 4.0. See [`THIRD-PARTY-NOTICES.md`](THIRD-PARTY-NOTICES.md).

## Before App Store submission

1. Register `com.allenvfits.eightwise` in your Apple Developer account, or replace it everywhere with another identifier you own.
2. In App Store Connect, create a subscription group and an auto-renewable monthly subscription with product ID `com.allenvfits.eightwise.plus.monthly`.
3. Set the US price to `$1.99`; Apple automatically handles local pricing and tax presentation.
4. Confirm that `https://allenvfits.github.io/eight-words/privacy/` and `/support/` are live.
5. Add your development team under **Signing & Capabilities**.
6. Create the app record, subscription review screenshot, App Privacy answers, and age rating. The current offline release uses the no-data-collected privacy profile; reassess it before enabling Supabase.
7. Verify the Privacy Policy, Terms, Support, and Attributions URLs in App Store Connect.

The repository includes a submission-ready [App Store privacy answer sheet](APP-PRIVACY-DISCLOSURE.md). The App Store privacy label is entered and published separately from the Xcode privacy manifest.

The exact App Store Connect fields, review notes, and remaining owner-only steps are in [`APP-STORE-SUBMISSION.md`](APP-STORE-SUBMISSION.md).

Windows-only release is supported through the manual **Upload to TestFlight** GitHub Actions workflow. It uses an ephemeral macOS runner and encrypted `testflight` environment secrets; Apple private keys, certificates, and provisioning profiles must never be committed to this public repository.

This build does not require an account, show advertising, or upload learning progress or saved words. It contacts Supabase only to download the read-only vocabulary catalog when configured. If you choose Apple's Kids Category, review the additional Kids Category rules before submitting.

## Product IDs

- App bundle: `com.allenvfits.eightwise`
- Monthly subscription: `com.allenvfits.eightwise.plus.monthly`

## Suggested App Store copy

**Name:** Eightwise: Daily Vocabulary

**Subtitle:** Eight words. A little wiser.

**Promotional text:** Learn eight useful words a day with clear definitions, real examples, and three levels made for curious minds of every age.

**Description:**

Build a stronger vocabulary one simple word at a time. Explore more than 3,000 words across three levels, read clear definitions, hear spoken pronunciation, split words into syllables, and practice with quizzes and tests. Learn eight words free each day, or unlock unlimited learning with Eightwise Plus for $1.99 a month.

No online account. No ads. No clutter. Local learner profiles keep progress, points, streaks, saved words, and rewards separate on one device.

## Generated app-icon prompt

The production icon was refined with the built-in image-generation tool using this prompt: “Recolor and refine the existing speech-bubble number 8 icon for Eightwise. Preserve the recognizable geometry; use deep midnight navy, electric violet, royal indigo, and mint; keep it crisp, centered, fully opaque, and legible at small sizes; no words, extra symbols, rounded-corner mask, or watermark.”
