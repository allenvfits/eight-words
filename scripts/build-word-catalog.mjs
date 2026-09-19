import fs from "node:fs";
import path from "node:path";

const sourceDirectory = process.argv[2];
const outputPath = process.argv[3] ?? path.join("EightWords", "Data", "WordCatalog.json");
const webOutputPath = process.argv[4];

if (!sourceDirectory) {
  throw new Error("Usage: node scripts/build-word-catalog.mjs <oewn-json-directory> [output-path]");
}

const levelSize = 1000;
const excludedFiles = new Set(["frames.json"]);
const unsafePattern = new RegExp(
  [
    "abortion", "abuse", "alcohol", "anus", "assault", "bastard", "battle", "bitch",
    "blood", "bomb", "breast", "brothel", "cancer", "cannabis", "cocaine", "condom",
    "corpse", "crime", "criminal", "cruelty", "dead", "death", "disease", "drug",
    "erotic", "execution", "explosive", "explicit", "feces", "firearm", "genital", "gun",
    "hallucination", "hell", "homicide", "injury", "jail", "kill", "military", "murder",
    "naked", "narcotic", "nazi", "no clothes", "nude", "nudity", "penis", "poison", "porn", "pregnan",
    "prison", "prostitute", "punishment", "rape", "rifle", "seduce", "sexual", "shoot",
    "soldier", "suffocat", "suicide", "terror", "tobacco", "torture", "troop", "urine",
    "vagina", "violence", "vomit", "warfare", "weapon", "whore", "wound"
  ].join("|"),
  "i"
);
const unsuitablePattern = /\b(archaic|obsolete|offensive|slang|vulgar)\b/i;

const synsets = new Map();
for (const filename of fs.readdirSync(sourceDirectory).sort()) {
  if (filename.startsWith("entries-") || excludedFiles.has(filename) || !filename.endsWith(".json")) continue;
  const document = JSON.parse(fs.readFileSync(path.join(sourceDirectory, filename), "utf8"));
  for (const [id, synset] of Object.entries(document)) synsets.set(id, synset);
}

const partNames = { n: "noun", v: "verb", a: "adjective", s: "adjective", r: "adverb" };
const byWord = new Map();

for (const filename of fs.readdirSync(sourceDirectory).filter(name => name.startsWith("entries-")).sort()) {
  const document = JSON.parse(fs.readFileSync(path.join(sourceDirectory, filename), "utf8"));
  for (const [rawLemma, parts] of Object.entries(document)) {
    const word = rawLemma.toLowerCase();
    if (!/^[a-z]{3,14}$/.test(word) || unsafePattern.test(word)) continue;

    for (const [partCode, entry] of Object.entries(parts)) {
      const partOfSpeech = partNames[partCode];
      if (!partOfSpeech || !Array.isArray(entry.sense) || entry.sense.length === 0) continue;

      const sense = entry.sense.find(item => synsets.has(item.synset));
      const synset = sense ? synsets.get(sense.synset) : undefined;
      const definition = synset?.definition?.find(value => typeof value === "string")?.trim();
      if (!sense || !definition || definition.length < 16 || definition.length > 220) continue;
      if (unsafePattern.test(definition) || unsuitablePattern.test(definition)) continue;

      const safeExample = (synset.example ?? []).find(value =>
        typeof value === "string" &&
        value.length >= 12 &&
        value.length <= 180 &&
        !unsafePattern.test(value) &&
        !unsuitablePattern.test(value)
      )?.trim() ?? "";
      const pronunciation = entry.pronunciation?.find(item => item?.value)?.value ?? "";
      const definitionWords = definition.split(/\s+/).length;
      const commonScore = entry.sense.length * 14 + (safeExample ? 8 : 0) + (pronunciation ? 5 : 0) - word.length * 0.7 - definitionWords * 0.25;
      const candidate = {
        word,
        pronunciation,
        partOfSpeech,
        definition: definition[0].toUpperCase() + definition.slice(1).replace(/[.;:]$/, "") + ".",
        example: safeExample ? safeExample[0].toUpperCase() + safeExample.slice(1).replace(/[.!?]$/, "") + "." : "",
        senseCount: entry.sense.length,
        definitionWords,
        commonScore
      };

      const previous = byWord.get(word);
      if (!previous || candidate.commonScore > previous.commonScore) byWord.set(word, candidate);
    }
  }
}

const available = [...byWord.values()];
const used = new Set();

function take(level, predicate, score) {
  const selected = available
    .filter(item => !used.has(item.word) && predicate(item))
    .sort((left, right) => score(right) - score(left) || left.word.localeCompare(right.word))
    .slice(0, levelSize);

  if (selected.length !== levelSize) throw new Error(`Only found ${selected.length} words for ${level}`);
  selected.forEach(item => used.add(item.word));
  return selected
    .sort((left, right) => left.word.localeCompare(right.word))
    .map(item => ({
      id: `${level}-${item.word}`,
      word: item.word,
      pronunciation: item.pronunciation,
      partOfSpeech: item.partOfSpeech,
      definition: item.definition,
      example: item.example,
      difficulty: level
    }));
}

const beginner = take(
  "beginner",
  item => item.word.length <= 8 && item.definitionWords <= 20 && item.senseCount >= 2,
  item => item.commonScore
);
const intermediate = take(
  "intermediate",
  item => item.word.length >= 5 && item.word.length <= 11 && item.definitionWords <= 24,
  item => item.commonScore + item.word.length * 0.8
);
const advanced = take(
  "advanced",
  item => item.word.length >= 7 && item.definitionWords <= 28,
  item => item.word.length * 5 + Math.min(item.commonScore, 38) + (item.pronunciation ? 3 : 0)
);

const catalog = { beginner, intermediate, advanced };
fs.writeFileSync(outputPath, `${JSON.stringify(catalog)}\n`);

if (webOutputPath) {
  const webCatalog = {
    everyday: beginner.map(item => ({ ...item, level: "everyday", source: "Open English WordNet 2025" })),
    growing: intermediate.map(item => ({ ...item, level: "growing", source: "Open English WordNet 2025" })),
    curious: advanced.map(item => ({ ...item, level: "curious", source: "Open English WordNet 2025" }))
  };
  const bank = Object.fromEntries(
    Object.entries(webCatalog).map(([level, words]) => [level, words.map(item => item.word)])
  );
  fs.writeFileSync(
    webOutputPath,
    `window.EIGHT_WORDS_CATALOG=${JSON.stringify(webCatalog)};\nwindow.EIGHT_WORDS_BANK=${JSON.stringify(bank)};\n`
  );
}

for (const [level, words] of Object.entries(catalog)) {
  const withExamples = words.filter(item => item.example).length;
  const withPronunciation = words.filter(item => item.pronunciation).length;
  console.log(`${level}: ${words.length} words, ${withExamples} examples, ${withPronunciation} pronunciations`);
}
