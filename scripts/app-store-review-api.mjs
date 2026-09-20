import { createPrivateKey, sign } from "node:crypto";
import { readFile } from "node:fs/promises";

const [command, versionID] = process.argv.slice(2);
const keyPath = process.env.ASC_KEY_PATH;
const keyID = process.env.ASC_KEY_ID;
const issuerID = process.env.ASC_ISSUER_ID;

if (!keyPath || !keyID || !issuerID) {
  throw new Error("ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID are required.");
}
if (!versionID) throw new Error("An App Store version ID is required.");

const b64url = value => Buffer.from(value).toString("base64url");
const now = Math.floor(Date.now() / 1000);
const unsigned = `${b64url(JSON.stringify({ alg: "ES256", kid: keyID, typ: "JWT" }))}.${b64url(JSON.stringify({ iss: issuerID, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }))}`;
const privateKey = createPrivateKey(await readFile(keyPath));
const signature = sign("sha256", Buffer.from(unsigned), { key: privateKey, dsaEncoding: "ieee-p1363" });
const token = `${unsigned}.${signature.toString("base64url")}`;

async function api(path, options = {}) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
      ...(options.headers ?? {})
    }
  });
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!response.ok) throw new Error(`Apple API ${response.status}: ${JSON.stringify(body)}`);
  return body;
}

async function getReviewDetail() {
  const response = await api(`/v1/appStoreVersions/${encodeURIComponent(versionID)}/appStoreReviewDetail`);
  return response.data;
}

if (command === "get") {
  const detail = await getReviewDetail();
  console.log(JSON.stringify({ id: detail.id, attributes: detail.attributes }));
} else if (command === "set") {
  const attributes = {
    contactFirstName: process.env.ASC_CONTACT_FIRST_NAME,
    contactLastName: process.env.ASC_CONTACT_LAST_NAME,
    contactPhone: process.env.ASC_CONTACT_PHONE,
    contactEmail: process.env.ASC_CONTACT_EMAIL,
    demoAccountRequired: false,
    notes: "Eightwise does not require an online account. Learner profiles, daily progress, selected difficulty, learned and saved words, quiz/test activity, points, streaks, and rewards remain on the device. This release uses its bundled vocabulary catalog and does not have Supabase credentials. Tap through eight words to display the Plus purchase screen. The first paywall tap loads and displays Apple's localized product information; a separate tap starts purchase. Use Restore Purchases to test entitlement restoration. The app uses StoreKit 2 for all digital purchases."
  };
  const missingContactFields = Object.entries(attributes)
    .filter(([name, value]) => name.startsWith("contact") && !value)
    .map(([name]) => name);
  if (missingContactFields.length > 0) {
    throw new Error(`Missing App Review contact environment variables: ${missingContactFields.join(", ")}`);
  }
  let detail;
  try { detail = await getReviewDetail(); } catch (error) {
    if (!String(error).includes("Apple API 404")) throw error;
  }
  const result = detail
    ? await api(`/v1/appStoreReviewDetails/${encodeURIComponent(detail.id)}`, {
        method: "PATCH",
        body: JSON.stringify({ data: { type: "appStoreReviewDetails", id: detail.id, attributes } })
      })
    : await api("/v1/appStoreReviewDetails", {
        method: "POST",
        body: JSON.stringify({
          data: {
            type: "appStoreReviewDetails",
            attributes,
            relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: versionID } } }
          }
        })
      });
  console.log(JSON.stringify({ id: result.data.id, attributes: result.data.attributes }));
} else {
  throw new Error(`Unknown command: ${command}`);
}
