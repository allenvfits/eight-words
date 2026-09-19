# Eight Words — App Store Privacy Answers

Use the profile that matches the exact build uploaded to App Store Connect. The intended production build contacts Supabase, so its retained API gateway logs must be included even though Eight Words has no account, advertising, or analytics SDK.

## App Store Connect answers for the Supabase build

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

- Selected difficulty, daily progress, and saved words stay in `UserDefaults` on the device.
- The cached vocabulary catalog stays in Application Support on the device.
- Spoken pronunciation uses Apple's on-device speech API.
- Apple processes payment details and StoreKit entitlements; Eight Words never receives payment-card data.
- The app does not request contacts, photos, microphone, camera, health, precise GPS location, or an advertising identifier.
- The app has no ads, third-party analytics SDK, cross-app tracking, or data broker sharing, so it does not need an App Tracking Transparency prompt.

## If the submitted build is offline-only

If both Supabase build settings are empty and the uploaded build uses only its bundled catalog, answer **No, we do not collect data from this app** and restore `NSPrivacyCollectedDataTypes` in `PrivacyInfo.xcprivacy` to an empty array before archiving. Change both the manifest and the App Store Connect answer before enabling Supabase in a later version.

## App Store Connect entry steps

1. Create the app record using the final registered bundle ID.
2. Open **App Privacy** and add `https://allenvfits.github.io/eight-words/privacy/` as the Privacy Policy URL.
3. Click **Get Started**, choose the Supabase or offline-only profile above, and complete every selected data type.
4. Review the Product Page Preview, click **Publish**, and keep the answers current when the data flow changes.

An Account Holder, Admin, or App Manager must publish these answers. Before submission, inspect the live Supabase project's API gateway logging and retention once more; update this sheet and App Store Connect if the configured service differs.

## Primary references

- [Apple: App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple: Manage app privacy in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- [Supabase: Logs in Studio](https://supabase.com/docs/guides/observability/logs)
- [Supabase: Log sources and captured fields](https://supabase.com/docs/guides/observability/log-field-reference)
- [Supabase: Pricing and log retention](https://supabase.com/pricing)
