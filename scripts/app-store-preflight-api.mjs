import { createPrivateKey, sign } from "node:crypto";
import { readFile } from "node:fs/promises";

const [appID, versionID] = process.argv.slice(2);
const keyPath = process.env.ASC_KEY_PATH;
const keyID = process.env.ASC_KEY_ID;
const issuerID = process.env.ASC_ISSUER_ID;

if (!keyPath || !keyID || !issuerID) throw new Error("ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID are required.");
if (!appID || !versionID) throw new Error("App and App Store version IDs are required.");

const b64url = value => Buffer.from(value).toString("base64url");
const now = Math.floor(Date.now() / 1000);
const unsigned = `${b64url(JSON.stringify({ alg: "ES256", kid: keyID, typ: "JWT" }))}.${b64url(JSON.stringify({ iss: issuerID, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }))}`;
const privateKey = createPrivateKey(await readFile(keyPath));
const signature = sign("sha256", Buffer.from(unsigned), { key: privateKey, dsaEncoding: "ieee-p1363" });
const token = `${unsigned}.${signature.toString("base64url")}`;

async function api(path) {
  const response = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" }
  });
  const text = await response.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!response.ok) return { error: response.status, body };
  return body;
}

const version = await api(`/v1/appStoreVersions/${encodeURIComponent(versionID)}?include=build,appStoreVersionLocalizations,appStoreReviewDetail`);
const app = await api(`/v1/apps/${encodeURIComponent(appID)}`);
const infos = await api(`/v1/apps/${encodeURIComponent(appID)}/appInfos?include=ageRatingDeclaration,appInfoLocalizations,primaryCategory,secondaryCategory&limit=50&limit%5BappInfoLocalizations%5D=50`);
const subscriptions = await api(`/v1/apps/${encodeURIComponent(appID)}/subscriptionGroups?include=subscriptions&limit=200&limit%5Bsubscriptions%5D=50`);
const submissions = await api(`/v1/apps/${encodeURIComponent(appID)}/reviewSubmissions?include=items,appStoreVersionForReview&limit=50&limit%5Bitems%5D=50`);

const included = infos.included ?? [];
const info = infos.data?.[0];
const infoLocalization = included.find(item => item.type === "appInfoLocalizations");
const ageRating = included.find(item => item.type === "ageRatingDeclarations");
const subscriptionItems = subscriptions.data ?? [];
const includedSubscriptions = subscriptions.included ?? [];

console.log(JSON.stringify({
  version: version.data ? {
    state: version.data.attributes.appStoreState,
    buildID: version.data.relationships?.build?.data?.id ?? null,
    reviewDetailID: version.data.relationships?.appStoreReviewDetail?.data?.id ?? null
  } : version,
  app: app.data ? {
    contentRightsDeclaration: app.data.attributes.contentRightsDeclaration,
    streamlinedPurchasingEnabled: app.data.attributes.streamlinedPurchasingEnabled
  } : app,
  appInfo: info ? {
    id: info.id,
    state: info.attributes.appStoreState,
    appStoreAgeRating: info.attributes.appStoreAgeRating,
    primaryCategory: info.relationships?.primaryCategory?.data?.id ?? null,
    secondaryCategory: info.relationships?.secondaryCategory?.data?.id ?? null,
    localization: infoLocalization?.attributes ?? null,
    ageRating: ageRating?.attributes ?? null
  } : infos,
  subscriptionGroups: subscriptionItems.map(item => ({ id: item.id, attributes: item.attributes })),
  subscriptions: includedSubscriptions.filter(item => item.type === "subscriptions").map(item => ({ id: item.id, attributes: item.attributes })),
  submissions: submissions.data?.map(item => ({ id: item.id, attributes: item.attributes })) ?? submissions
}));
