# Accounts and rewards plan

## What the Windows preview does now

The browser build supports multiple profiles on one computer. Each profile has separate:

- Daily word progress
- Learned-word history
- Quiz and test scores
- Points and unlocked rewards
- Streak, difficulty level, and Plus preview status
- Saved words for quick review

The preview stores this information in the browser. It deliberately does not ask for an email address, birth date, or password. That is safer for a broad-age prototype, but it is not yet a real cloud account and will not sync to another device.

## Recommended point economy

| Action | Points | Limit |
|---|---:|---|
| Learn a word | 10 | Once per word each day |
| Correct quiz answer | 20 | Once per word each day |
| Correct test answer | 15 | Once per word each day |
| Complete the daily eight | 50 | Once per day |
| Perfect ten-question test | 100 | Once per day |

This makes the first reward reachable in about two or three active days while keeping the more visible badge meaningful.

## Launch rewards

| Reward | Price | Purpose |
|---|---:|---|
| Sunshine theme | 250 points | Fast first reward |
| Streak shield | 500 points | Protects one missed day |
| Galaxy theme | 800 points | Medium-term goal |
| Word Master badge | 1,200 points | Profile status reward |

These points cannot be purchased, transferred, or converted to money. Rewards are deterministic—there are no loot boxes or random prizes.

## Real account architecture

For production, use a managed authentication and database service. Support Sign in with Apple on iPhone plus email magic-link sign-in on Windows. Keep the minimum data required: account ID, display name, progress, subscription entitlement, and optional parent-consent status when legally necessary.

Suggested database records:

- `accounts`: ID, authentication provider, created date, account status
- `learner_profiles`: account ID, display name, selected level, streak, theme
- `word_progress`: profile ID, word ID, first learned date, review strength
- `points_ledger`: profile ID, unique event ID, point amount, reason, date
- `rewards`: reward ID, point price, type, active status
- `redemptions`: profile ID, reward ID, redeemed date
- `entitlements`: account ID, Apple transaction reference, subscription status

Points must be awarded by the server using a unique event ID. The client should never be trusted to send its own balance; that prevents people from editing browser storage to create points.

## Real-world prizes: later, with legal review

The safest launch is in-app rewards only. If a later version offers physical prizes, treat it as a separate contest program. It needs official rules, eligibility and geographic limits, an age/parental-consent plan, fraud controls, fulfillment and tax handling, and a clear statement that Apple does not sponsor or administer it. Do not let purchased points or a paid subscription improve a person's odds of winning.

Apple's App Review Guidelines say sweepstakes and contests must be sponsored by the app developer, official rules must appear in the app, and those rules must state that Apple is not involved. Rules and local law should be reviewed by a qualified attorney before launch.

## Subscription recommendation

Keep the current **$1.99/month** Plus plan:

- Free: eight daily words, quizzes, tests, points, and rewards
- Plus: unlimited words with no daily cap, a surprise-word explorer, deeper review sessions, expanded progress history, and future family sync

On iPhone, digital subscriptions and paid digital features should use Apple in-app purchase. The Windows preview simulates Plus but does not collect payment.
