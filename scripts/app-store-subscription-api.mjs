import { createHash, createPrivateKey, sign } from "node:crypto";
import { readFile } from "node:fs/promises";
import { basename } from "node:path";

const [command, appID, screenshotPath] = process.argv.slice(2);
const keyPath = process.env.ASC_KEY_PATH;
const keyID = process.env.ASC_KEY_ID;
const issuerID = process.env.ASC_ISSUER_ID;

if (!keyPath || !keyID || !issuerID) throw new Error("ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID are required.");
if (!appID) throw new Error("An App Store Connect app ID is required.");

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

async function listGroups() {
  return (await api(`/v1/apps/${encodeURIComponent(appID)}/subscriptionGroups?limit=200`)).data;
}

async function listSubscriptions(groupID) {
  return (await api(`/v1/subscriptionGroups/${encodeURIComponent(groupID)}/subscriptions?limit=50`)).data;
}

async function ensureProduct() {
  let group = (await listGroups()).find(item => item.attributes.referenceName === "Eightwise Plus");
  if (!group) {
    group = (await api("/v1/subscriptionGroups", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptionGroups",
          attributes: { referenceName: "Eightwise Plus" },
          relationships: { app: { data: { type: "apps", id: appID } } }
        }
      })
    })).data;
  }

  let subscription = (await listSubscriptions(group.id)).find(item => item.attributes.productId === "com.allenvfits.eightwise.plus.monthly");
  if (!subscription) {
    subscription = (await api("/v1/subscriptions", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptions",
          attributes: {
            name: "Eightwise Plus Monthly",
            productId: "com.allenvfits.eightwise.plus.monthly",
            familySharable: true,
            subscriptionPeriod: "ONE_MONTH",
            groupLevel: 1,
            reviewNote: "Unlocks unlimited vocabulary browsing across all difficulty levels. Free users receive eight words per day. Tap through eight words to show the paywall, then choose Eightwise Plus."
          },
          relationships: { group: { data: { type: "subscriptionGroups", id: group.id } } }
        }
      })
    })).data;
  }

  const localizations = (await api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/subscriptionLocalizations?limit=50`)).data;
  if (!localizations.some(item => item.attributes.locale === "en-US")) {
    await api("/v1/subscriptionLocalizations", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptionLocalizations",
          attributes: {
            locale: "en-US",
            name: "Eightwise Plus",
            description: "Unlimited words across every difficulty level."
          },
          relationships: { subscription: { data: { type: "subscriptions", id: subscription.id } } }
        }
      })
    });
  }

  const groupLocalizations = (await api(`/v1/subscriptionGroups/${encodeURIComponent(group.id)}/subscriptionGroupLocalizations?limit=50`)).data;
  if (!groupLocalizations.some(item => item.attributes.locale === "en-US")) {
    await api("/v1/subscriptionGroupLocalizations", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptionGroupLocalizations",
          attributes: { locale: "en-US", name: "Eightwise Plus" },
          relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: group.id } } }
        }
      })
    });
  }
  return { group, subscription };
}

async function ensureReviewScreenshot(subscriptionID) {
  if (!screenshotPath) throw new Error("A review screenshot path is required.");
  try {
    const existing = await api(`/v1/subscriptions/${encodeURIComponent(subscriptionID)}/appStoreReviewScreenshot`);
    if (existing.data?.attributes?.assetDeliveryState?.state === "COMPLETE") return existing.data;
  } catch (error) {
    if (!String(error).includes("Apple API 404")) throw error;
  }

  const file = await readFile(screenshotPath);
  const fileName = basename(screenshotPath);
  const reservation = await api("/v1/subscriptionAppStoreReviewScreenshots", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "subscriptionAppStoreReviewScreenshots",
        attributes: { fileSize: file.length, fileName },
        relationships: { subscription: { data: { type: "subscriptions", id: subscriptionID } } }
      }
    })
  });
  const screenshot = reservation.data;
  for (const operation of screenshot.attributes.uploadOperations) {
    const chunk = file.subarray(operation.offset, operation.offset + operation.length);
    const response = await fetch(operation.url, {
      method: operation.method,
      headers: Object.fromEntries(operation.requestHeaders.map(header => [header.name, header.value])),
      body: chunk
    });
    if (!response.ok) throw new Error(`Review screenshot upload failed: HTTP ${response.status}`);
  }
  const checksum = createHash("md5").update(file).digest("hex");
  await api(`/v1/subscriptionAppStoreReviewScreenshots/${encodeURIComponent(screenshot.id)}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "subscriptionAppStoreReviewScreenshots",
        id: screenshot.id,
        attributes: { uploaded: true, sourceFileChecksum: checksum }
      }
    })
  });
  for (let attempt = 0; attempt < 30; attempt += 1) {
    await new Promise(resolve => setTimeout(resolve, 3000));
    const result = await api(`/v1/subscriptionAppStoreReviewScreenshots/${encodeURIComponent(screenshot.id)}`);
    const state = result.data.attributes.assetDeliveryState?.state;
    if (state === "COMPLETE") return result.data;
    if (state === "FAILED") throw new Error(`Apple rejected the review screenshot: ${JSON.stringify(result.data.attributes.assetDeliveryState)}`);
  }
  throw new Error("Timed out waiting for review screenshot processing.");
}

async function inspect(subscription) {
  const [localizations, prices, planAvailabilities, screenshot] = await Promise.all([
    api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/subscriptionLocalizations?limit=50`),
    api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/prices?filter%5Bterritory%5D=USA&include=subscriptionPricePoint,territory&limit=200`),
    api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/planAvailabilities?include=availableTerritories&limit=50&limit%5BavailableTerritories%5D=50`),
    api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/appStoreReviewScreenshot`).catch(error => ({ error: String(error) }))
  ]);
  return {
    subscription: { id: subscription.id, attributes: subscription.attributes },
    localizations: localizations.data.map(item => item.attributes),
    USAprices: prices.data.map(item => item.attributes),
    planAvailabilities: planAvailabilities.data.map(item => item.attributes),
    screenshot: screenshot.data ? { id: screenshot.data.id, state: screenshot.data.attributes.assetDeliveryState?.state } : screenshot
  };
}

const { group, subscription } = await ensureProduct();
if (command === "setup") {
  const screenshot = await ensureReviewScreenshot(subscription.id);
  console.log(JSON.stringify({
    group: { id: group.id, referenceName: group.attributes.referenceName },
    subscription: { id: subscription.id, ...subscription.attributes },
    reviewScreenshot: { id: screenshot.id, state: screenshot.attributes.assetDeliveryState?.state }
  }));
} else if (command === "info") {
  console.log(JSON.stringify(await inspect(subscription)));
} else if (command === "price-points") {
  const points = await api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/pricePoints?filter%5Bterritory%5D=USA&include=territory&limit=8000`);
  const matches = points.data.filter(item => item.attributes.customerPrice === "1.99");
  console.log(JSON.stringify({ subscriptionID: subscription.id, matches: matches.map(item => ({ id: item.id, ...item.attributes })) }));
} else if (command === "set-price") {
  const points = await api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/pricePoints?filter%5Bterritory%5D=USA&include=territory&limit=8000`);
  const pricePoint = points.data.find(item => item.attributes.customerPrice === "1.99");
  if (!pricePoint) throw new Error("Apple did not return a $1.99 USD subscription price point.");
  try {
    await api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/subscriptionAvailability`);
  } catch (error) {
    if (!String(error).includes("Apple API 404")) throw error;
    const territories = await api("/v1/territories?limit=200");
    await api("/v1/subscriptionAvailabilities", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptionAvailabilities",
          attributes: { availableInNewTerritories: true },
          relationships: {
            subscription: { data: { type: "subscriptions", id: subscription.id } },
            availableTerritories: {
              data: territories.data.map(item => ({ type: "territories", id: item.id }))
            }
          }
        }
      })
    });
  }

  const equalizations = await api(`/v1/subscriptionPricePoints/${encodeURIComponent(pricePoint.id)}/equalizations?include=territory&limit=200`);
  const allPricePoints = [pricePoint, ...equalizations.data];
  const existingPrices = await api(`/v1/subscriptions/${encodeURIComponent(subscription.id)}/prices?include=subscriptionPricePoint,territory&limit=200`);
  const existingPointIDs = new Set(existingPrices.data.map(item => item.relationships?.subscriptionPricePoint?.data?.id).filter(Boolean));
  const pending = allPricePoints.filter(item => !existingPointIDs.has(item.id));
  let created = 0;
  for (let index = 0; index < pending.length; index += 8) {
    const batch = pending.slice(index, index + 8);
    await Promise.all(batch.map(item => api("/v1/subscriptionPrices", {
      method: "POST",
      body: JSON.stringify({
        data: {
          type: "subscriptionPrices",
          attributes: { startDate: null },
          relationships: {
            subscription: { data: { type: "subscriptions", id: subscription.id } },
            subscriptionPricePoint: { data: { type: "subscriptionPricePoints", id: item.id } }
          }
        }
      })
    })));
    created += batch.length;
  }

  console.log(JSON.stringify({
    subscriptionID: subscription.id,
    USApricePoint: { id: pricePoint.id, ...pricePoint.attributes },
    configuredTerritories: allPricePoints.length,
    newlyCreatedPrices: created
  }));
} else {
  throw new Error(`Unknown command: ${command}`);
}
