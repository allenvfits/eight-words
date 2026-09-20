import { createHash, createPrivateKey, sign } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import { basename, join } from "node:path";

const [command, appID, screenshotRoot] = process.argv.slice(2);
const keyPath = process.env.ASC_KEY_PATH;
const keyID = process.env.ASC_KEY_ID;
const issuerID = process.env.ASC_ISSUER_ID;

if (!keyPath || !keyID || !issuerID) {
  throw new Error("ASC_KEY_PATH, ASC_KEY_ID, and ASC_ISSUER_ID are required.");
}
if (!appID) throw new Error("An App Store Connect app ID is required.");

const b64url = value => Buffer.from(value).toString("base64url");
const now = Math.floor(Date.now() / 1000);
const header = b64url(JSON.stringify({ alg: "ES256", kid: keyID, typ: "JWT" }));
const payload = b64url(JSON.stringify({ iss: issuerID, iat: now, exp: now + 900, aud: "appstoreconnect-v1" }));
const unsigned = `${header}.${payload}`;
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

async function versionAndLocalization() {
  const versions = await api(`/v1/apps/${encodeURIComponent(appID)}/appStoreVersions?filter%5Bplatform%5D=IOS&limit=50`);
  const version = versions.data.find(item => item.attributes.versionString === "1.0" && item.attributes.appStoreState === "PREPARE_FOR_SUBMISSION")
    ?? versions.data.find(item => item.attributes.appStoreState === "PREPARE_FOR_SUBMISSION");
  if (!version) throw new Error("No editable iOS App Store version was found.");
  const localizations = await api(`/v1/appStoreVersions/${encodeURIComponent(version.id)}/appStoreVersionLocalizations?limit=50`);
  const localization = localizations.data.find(item => item.attributes.locale === "en-US") ?? localizations.data[0];
  if (!localization) throw new Error("No App Store version localization was found.");
  return { version, localization };
}

async function screenshotSets(localizationID) {
  const response = await api(`/v1/appStoreVersionLocalizations/${encodeURIComponent(localizationID)}/appScreenshotSets?limit=50`);
  return response.data;
}

async function ensureSet(localizationID, displayType) {
  const existing = (await screenshotSets(localizationID)).find(item => item.attributes.screenshotDisplayType === displayType);
  if (existing) return existing;
  const created = await api("/v1/appScreenshotSets", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "appScreenshotSets",
        attributes: { screenshotDisplayType: displayType },
        relationships: {
          appStoreVersionLocalization: {
            data: { type: "appStoreVersionLocalizations", id: localizationID }
          }
        }
      }
    })
  });
  return created.data;
}

async function screenshotsForSet(setID) {
  const response = await api(`/v1/appScreenshotSets/${encodeURIComponent(setID)}/appScreenshots?limit=200`);
  return response.data;
}

async function uploadScreenshot(setID, filePath) {
  const file = await readFile(filePath);
  const fileName = basename(filePath);
  const reservation = await api("/v1/appScreenshots", {
    method: "POST",
    body: JSON.stringify({
      data: {
        type: "appScreenshots",
        attributes: { fileSize: file.length, fileName },
        relationships: {
          appScreenshotSet: { data: { type: "appScreenshotSets", id: setID } }
        }
      }
    })
  });

  const screenshot = reservation.data;
  for (const operation of screenshot.attributes.uploadOperations) {
    const chunk = file.subarray(operation.offset, operation.offset + operation.length);
    const response = await fetch(operation.url, {
      method: operation.method,
      headers: Object.fromEntries(operation.requestHeaders.map(headerItem => [headerItem.name, headerItem.value])),
      body: chunk
    });
    if (!response.ok) throw new Error(`Asset upload failed for ${fileName}: HTTP ${response.status}`);
  }

  const checksum = createHash("md5").update(file).digest("hex");
  await api(`/v1/appScreenshots/${encodeURIComponent(screenshot.id)}`, {
    method: "PATCH",
    body: JSON.stringify({
      data: {
        type: "appScreenshots",
        id: screenshot.id,
        attributes: { uploaded: true, sourceFileChecksum: checksum }
      }
    })
  });
  return { id: screenshot.id, fileName };
}

async function waitForScreenshots(items) {
  const pending = new Map(items.map(item => [item.id, item.fileName]));
  for (let attempt = 0; attempt < 30 && pending.size; attempt += 1) {
    await new Promise(resolve => setTimeout(resolve, 4000));
    for (const [id, fileName] of [...pending]) {
      const response = await api(`/v1/appScreenshots/${encodeURIComponent(id)}`);
      const state = response.data.attributes.assetDeliveryState?.state;
      if (state === "COMPLETE") pending.delete(id);
      if (state === "FAILED") throw new Error(`Apple rejected screenshot processing for ${fileName}: ${JSON.stringify(response.data.attributes.assetDeliveryState)}`);
    }
  }
  if (pending.size) throw new Error(`Timed out waiting for screenshot processing: ${[...pending.values()].join(", ")}`);
}

async function filesIn(directory) {
  const names = (await readdir(directory)).filter(name => name.toLowerCase().endsWith(".png")).sort();
  if (names.length !== 5) throw new Error(`Expected five PNG files in ${directory}, found ${names.length}.`);
  for (const name of names) {
    const details = await stat(join(directory, name));
    if (!details.isFile() || details.size === 0) throw new Error(`Invalid screenshot file: ${name}`);
  }
  return names.map(name => join(directory, name));
}

const { version, localization } = await versionAndLocalization();

if (command === "info") {
  const sets = await screenshotSets(localization.id);
  const output = [];
  for (const set of sets) {
    const screenshots = await screenshotsForSet(set.id);
    output.push({ id: set.id, displayType: set.attributes.screenshotDisplayType, screenshotCount: screenshots.length });
  }
  console.log(JSON.stringify({ versionID: version.id, version: version.attributes.versionString, state: version.attributes.appStoreState, localizationID: localization.id, locale: localization.attributes.locale, sets: output }));
} else if (command === "upload") {
  if (!screenshotRoot) throw new Error("A screenshot root directory is required for upload.");
  const targets = [
    { displayType: "APP_IPHONE_65", directory: join(screenshotRoot, "iPhone-6.5") },
    { displayType: "APP_IPAD_PRO_3GEN_129", directory: join(screenshotRoot, "iPad-13") }
  ];
  const uploaded = [];
  for (const target of targets) {
    const set = await ensureSet(localization.id, target.displayType);
    const existing = await screenshotsForSet(set.id);
    if (existing.length) throw new Error(`${target.displayType} already has ${existing.length} screenshot(s); refusing to duplicate them.`);
    const files = await filesIn(target.directory);
    for (const filePath of files) {
      uploaded.push(await uploadScreenshot(set.id, filePath));
    }
  }
  await waitForScreenshots(uploaded);
  console.log(JSON.stringify({ uploaded: uploaded.map(item => item.fileName), count: uploaded.length, locale: localization.attributes.locale }));
} else {
  throw new Error(`Unknown command: ${command}`);
}
