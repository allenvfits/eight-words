import { createPrivateKey, sign } from "node:crypto";
import { readFile } from "node:fs/promises";

const [appID, appInfoID, localizationID] = process.argv.slice(2);
const keyPath = process.env.ASC_KEY_PATH;
const keyID = process.env.ASC_KEY_ID;
const issuerID = process.env.ASC_ISSUER_ID;

if (!keyPath || !keyID || !issuerID) throw new Error("ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID are required.");
if (!appID || !appInfoID || !localizationID) throw new Error("App, app info, and localization IDs are required.");

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

const app = await api(`/v1/apps/${encodeURIComponent(appID)}`, {
  method: "PATCH",
  body: JSON.stringify({
    data: {
      type: "apps",
      id: appID,
      attributes: { contentRightsDeclaration: "USES_THIRD_PARTY_CONTENT" }
    }
  })
});

const appInfo = await api(`/v1/appInfos/${encodeURIComponent(appInfoID)}`, {
  method: "PATCH",
  body: JSON.stringify({
    data: {
      type: "appInfos",
      id: appInfoID,
      relationships: {
        primaryCategory: { data: { type: "appCategories", id: "EDUCATION" } },
        secondaryCategory: { data: { type: "appCategories", id: "REFERENCE" } }
      }
    }
  })
});

const localization = await api(`/v1/appInfoLocalizations/${encodeURIComponent(localizationID)}`, {
  method: "PATCH",
  body: JSON.stringify({
    data: {
      type: "appInfoLocalizations",
      id: localizationID,
      attributes: {
        subtitle: "Eight words. A little wiser.",
        privacyPolicyUrl: "https://allenvfits.github.io/eight-words/privacy/"
      }
    }
  })
});

const none = "NONE";
const ageRating = await api(`/v1/ageRatingDeclarations/${encodeURIComponent(appInfoID)}`, {
  method: "PATCH",
  body: JSON.stringify({
    data: {
      type: "ageRatingDeclarations",
      id: appInfoID,
      attributes: {
        advertising: false,
        alcoholTobaccoOrDrugUseOrReferences: none,
        contests: none,
        gambling: false,
        gamblingSimulated: none,
        gunsOrOtherWeapons: none,
        healthOrWellnessTopics: false,
        lootBox: false,
        medicalOrTreatmentInformation: none,
        messagingAndChat: false,
        parentalControls: false,
        profanityOrCrudeHumor: none,
        ageAssurance: false,
        sexualContentGraphicAndNudity: none,
        sexualContentOrNudity: none,
        socialMedia: false,
        socialMediaAgeRestricted: false,
        horrorOrFearThemes: none,
        matureOrSuggestiveThemes: none,
        unrestrictedWebAccess: false,
        userGeneratedContent: false,
        violenceCartoonOrFantasy: none,
        violenceRealisticProlongedGraphicOrSadistic: none,
        violenceRealistic: none,
        ageRatingOverrideV2: none,
        koreaAgeRatingOverride: none,
        kidsAgeBand: null
      }
    }
  })
});

console.log(JSON.stringify({
  contentRightsDeclaration: app.data.attributes.contentRightsDeclaration,
  appInfoID: appInfo.data.id,
  subtitle: localization.data.attributes.subtitle,
  privacyPolicyUrl: localization.data.attributes.privacyPolicyUrl,
  appStoreAgeRating: ageRating.data.attributes
}));
