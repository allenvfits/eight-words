# Eight Words

Eight Words is a native SwiftUI vocabulary app for iPhone and iPad. It gives people a calm, age-inclusive way to learn words at three levels: **Everyday**, **Growing**, and **Curious**.

The repository also includes a Windows-friendly browser preview in `web/` with a 7,000-word candidate library, clickable syllable guides, multiple local profiles, prominent difficulty controls, saved-word favorites, quizzes, ten-question tests, points, streaks, and redeemable in-app rewards.

## Run on Windows

Double-click `web/start-windows.bat`. It opens the browser preview at `http://127.0.0.1:8765`. Keep the command window open while using the app, then close it when finished.

The Windows preview stores profiles on that computer only. The recommended cloud account architecture and reward economy are documented in `web/ACCOUNTS-AND-REWARDS.md`.

## Included

- 60 hand-written word, definition, pronunciation, and example entries
- Eight free words each calendar day, saved on-device
- Level switching at any time
- Spoken pronunciation using the system voice
- A StoreKit 2 monthly subscription flow for unlimited words
- A clear unlimited mode with no daily cap for `$1.99/month`
- Saved-word favorites with a dedicated review screen
- Restore purchases and transaction verification
- Dynamic Type, VoiceOver labels, reduced-motion handling, and iPad support
- A local StoreKit testing configuration with a `$1.99/month` product
- An Apple privacy manifest declaring local preferences use
- Public privacy and support pages published from `docs/`
- GitHub Actions checks for the iOS build, plists, app icon, and web JavaScript

## Run it

1. Open `EightWords.xcodeproj` in a current App Store-supported version of Xcode on macOS.
2. Choose the **EightWords** scheme and an iPhone simulator.
3. Build and run.

The shared scheme uses `EightWords.storekit`, so the paywall can be tested locally without creating an App Store Connect product first. Use **Debug > StoreKit > Manage Transactions** in Xcode to manage test purchases.

## Before App Store submission

1. Change `com.eightwords.app` to a unique bundle ID registered to your Apple Developer account.
2. In App Store Connect, create a subscription group and an auto-renewable monthly subscription with product ID `com.eightwords.plus.monthly`.
3. Set the US price to `$1.99`; Apple automatically handles local pricing and tax presentation.
4. Confirm that `https://allenvfits.github.io/eight-words/privacy/` and `/support/` are live.
5. Add your development team under **Signing & Capabilities**.
6. Expand the recurring content library or switch Plus to a one-time purchase so the paid product clearly delivers the value advertised to customers and App Review.
7. Create the app record, subscription review screenshot, App Privacy answers, and age rating.

The exact App Store Connect fields, review notes, and remaining owner-only steps are in [`APP-STORE-SUBMISSION.md`](APP-STORE-SUBMISSION.md).

This build does not collect personal data, show advertising, or require an account. That keeps the experience appropriate for a broad audience. If you choose Apple's Kids Category, review the additional Kids Category rules before submitting.

## Product IDs

- App bundle: `com.eightwords.app`
- Monthly subscription: `com.eightwords.plus.monthly`

## Suggested App Store copy

**Subtitle:** A little smarter every day

**Promotional text:** Learn eight useful words a day with clear definitions, real examples, and three levels made for curious minds of every age.

**Description:**

Build a stronger vocabulary one simple word at a time. Choose your level, read a clear definition, hear the pronunciation, and see the word used in a natural sentence. Learn eight words free each day, or unlock unlimited learning with Eight Words Plus for $1.99 a month.

No accounts. No ads. No clutter. Just good words, made easy.

## Generated app-icon prompt

The icon was created with the built-in image-generation tool using this prompt: “Create a polished, minimalist iOS app icon for an age-inclusive vocabulary app called Eight Words. One bold, friendly number 8 as the only symbol, subtly formed from two overlapping speech bubbles. Crisp flat vector-like design; near-black charcoal, warm oat/cream, and a small golden-yellow accent; centered and legible at small sizes; no extra words or watermark.”
