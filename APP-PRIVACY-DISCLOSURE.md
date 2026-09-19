# Eight Words — App Store Privacy Answers

Use the profile that matches the exact build uploaded to App Store Connect. The current release build is offline-only: it uses the bundled catalog and stores learner data locally on the device.

## App Store Connect answers for the current offline release

Answer **No, we do not collect data from this app**. The checked-in `PrivacyInfo.xcprivacy` has an empty `NSPrivacyCollectedDataTypes` array and declares only the required-reason API used for local preferences.

## Answers for a future Supabase-enabled build

On **App Privacy**, answer **Yes, we collect data from this app**, then add these data types:

| App Store data type | Why it is included | Purpose | Linked to the user | Used for tracking |
| --- | --- | --- | --- | --- |
| Coarse Location | Supabase gateway logs can retain IP-derived country, region, city, and approximate coordinates. | App Functionality | Yes | No |
| Product Interaction | A catalog request records its time and endpoint, which can indicate that the app opened or refreshed its words. | App Functionality | Yes | No |
| Other Diagnostic Data | Supabase gateway logs can retain IP address, user agent, request status, request path, and latency metadata for delivery, security, and troubleshooting. | App Functionality | Yes | No |

The **Linked to the user** answer above is intentionally conservative. The app does not create an account or send a name, email address, advertising identifier, saved words, or learning progress, but the retained request log contains an IP address and device/network metadata. Do not select **Device ID** unless the production service later assigns or stores a device-level identifier.

For every listed data type:

- Select only **App Functionality** as the purpose.
- Answer **No** to tracking.
- Do not add advertising or marketing purposes.
- Do not add Analytics unless the project later uses request logs to measure user behavior or audience characteristics.

## Data that does not need to be added

- Learner profiles, selected difficulty, daily progress, learned and saved words, quiz/test activity, points, streaks, and rewards stay in `UserDefaults` on the device.
- The cached vocabulary catalog stays in Application Support on the device.
- Spoken pronunciation uses Apple's on-device speech API.
- Apple processes payment details and StoreKit entitlements; Eight Words never receives payment-card data.
- The app does not request contacts, photos, microphone, camera, health, precise GPS location, or an advertising identifier.
- The app has no ads, third-party analytics SDK, cross-app tracking, or data broker sharing, so it does not need an App Tracking Transparency prompt.

Do not use the Supabase answers for the current release. Before enabling Supabase in a later version, update both the privacy manifest and App Store Connect disclosures to match the production service.

## App Store Connect entry steps

1. Create the app record using the final registered bundle ID.
2. Open **App Privacy** and add `https://allenvfits.github.io/eight-words/privacy/` as the Privacy Policy URL.
3. Click **Get Started**, choose **No, we do not collect data from this app**, and publish the answer.
4. Review the Product Page Preview, click **Publish**, and keep the answers current when the data flow changes.

An Account Holder, Admin, or App Manager must publish these answers. If a network backend is enabled before submission, stop and reassess the declarations first.

## Primary references

- [Apple: App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: Manage app privacy in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Supabase: Logs in Studio](https://supabase.com/docs/guides/observability/logs)
- [Supabase: Log sources and captured fields](https://supabase.com/docs/guides/observability/log-field-reference)
- [Supabase: Pricing and log retention](https://supabase.com/pricing)
