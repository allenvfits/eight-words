"use strict";

const STORAGE_KEY = "eightWords.profiles.v2";
const ACTIVE_KEY = "eightWords.activeProfile.v2";
const REMOTE_DICTIONARY = "https://raw.githubusercontent.com/mhollingshead/open-dictionary/main/api";
const LEVELS = {
  everyday: { label: "Everyday", color: "#257b60" },
  growing: { label: "Growing", color: "#575dc8" },
  curious: { label: "Curious", color: "#d35d55" }
};

const FALLBACK_WORDS = [
  { word: "brisk", partOfSpeech: "adjective", definition: "Quick, lively, and full of energy.", example: "We took a brisk walk before breakfast.", level: "everyday" },
  { word: "cozy", partOfSpeech: "adjective", definition: "Warm, comfortable, and relaxing.", example: "The reading corner felt cozy on the rainy day.", level: "everyday" },
  { word: "glimpse", partOfSpeech: "noun", definition: "A quick or partial look.", example: "We caught a glimpse of the deer in the woods.", level: "everyday" },
  { word: "harmony", partOfSpeech: "noun", definition: "A pleasing way that sounds or people work together.", example: "Their voices blended in harmony.", level: "everyday" },
  { word: "invent", partOfSpeech: "verb", definition: "To create something that did not exist before.", example: "They worked together to invent a new game.", level: "everyday" },
  { word: "observe", partOfSpeech: "verb", definition: "To watch or notice something carefully.", example: "We sat quietly to observe the birds.", level: "everyday" },
  { word: "candid", partOfSpeech: "adjective", definition: "Honest and direct, even when the truth is difficult.", example: "She gave a candid answer about the project.", level: "growing" },
  { word: "diligent", partOfSpeech: "adjective", definition: "Careful and persistent in your work.", example: "His diligent practice made the song sound effortless.", level: "growing" },
  { word: "eloquent", partOfSpeech: "adjective", definition: "Fluent, clear, and persuasive in expression.", example: "Her eloquent speech moved the audience.", level: "growing" },
  { word: "lucid", partOfSpeech: "adjective", definition: "Expressed clearly and easy to understand.", example: "The guide gave a lucid explanation of the rules.", level: "growing" },
  { word: "resilient", partOfSpeech: "adjective", definition: "Able to recover quickly after difficulty.", example: "The resilient little tree grew after the fire.", level: "growing" },
  { word: "versatile", partOfSpeech: "adjective", definition: "Able to do many different things well.", example: "A plain notebook is a versatile tool.", level: "growing" },
  { word: "ephemeral", partOfSpeech: "adjective", definition: "Lasting for only a short time.", example: "The artist created an ephemeral pattern in the sand.", level: "curious" },
  { word: "gregarious", partOfSpeech: "adjective", definition: "Sociable and fond of company.", example: "Her gregarious nature made newcomers feel welcome.", level: "curious" },
  { word: "nuance", partOfSpeech: "noun", definition: "A subtle difference in meaning, feeling, or appearance.", example: "The actor captured every nuance of the character.", level: "curious" },
  { word: "reticent", partOfSpeech: "adjective", definition: "Not revealing thoughts or feelings readily.", example: "She was reticent at first, then shared her idea.", level: "curious" },
  { word: "sagacious", partOfSpeech: "adjective", definition: "Showing wise judgment and good sense.", example: "The sagacious mentor encouraged patience.", level: "curious" },
  { word: "ubiquitous", partOfSpeech: "adjective", definition: "Present or found nearly everywhere.", example: "Smartphones have become ubiquitous in many cities.", level: "curious" }
];

const REWARDS = [
  { id: "sunshine", icon: "☀", name: "Sunshine theme", description: "Give the app a warm golden glow.", cost: 250, kind: "theme", value: "sunshine" },
  { id: "shield", icon: "◆", name: "Streak shield", description: "Protect your streak if you miss one day.", cost: 500, kind: "shield", value: 1 },
  { id: "galaxy", icon: "✦", name: "Galaxy theme", description: "Add a calm indigo look to your learning.", cost: 800, kind: "theme", value: "galaxy" },
  { id: "wordmaster", icon: "★", name: "Word Master badge", description: "A permanent badge for your profile.", cost: 1200, kind: "badge", value: "Word Master" }
];

const SYLLABLE_EXCEPTIONS = {
  business: ["busi", "ness"],
  camera: ["cam", "er", "a"],
  chocolate: ["choc", "o", "late"],
  comfortable: ["com", "fort", "a", "ble"],
  different: ["dif", "fer", "ent"],
  every: ["ev", "er", "y"],
  family: ["fam", "i", "ly"],
  favorite: ["fa", "vor", "ite"],
  fire: ["fire"],
  flower: ["flow", "er"],
  hour: ["hour"],
  interesting: ["in", "ter", "est", "ing"],
  orange: ["or", "ange"],
  people: ["peo", "ple"],
  quiet: ["qui", "et"],
  science: ["sci", "ence"],
  several: ["sev", "er", "al"],
  special: ["spe", "cial"],
  vegetable: ["veg", "e", "ta", "ble"],
  wednesday: ["wednes", "day"],
  wonder: ["won", "der"]
};

let profiles = loadProfiles();
let activeProfile = null;
let currentWord = null;
let currentView = "learn";
let quizSession = null;
let testSession = null;
let toastTimer = null;

const $ = selector => document.querySelector(selector);
const $$ = selector => [...document.querySelectorAll(selector)];

function loadProfiles() {
  try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || []; }
  catch { return []; }
}

function saveProfiles() {
  const index = profiles.findIndex(profile => profile.id === activeProfile?.id);
  if (index >= 0) profiles[index] = activeProfile;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(profiles));
}

function makeProfile(name, level) {
  const today = dayKey();
  return {
    id: `profile-${Date.now()}-${Math.random().toString(16).slice(2)}`,
    name: name.trim(),
    level,
    points: 0,
    streak: 1,
    lastActiveDay: today,
    learned: [],
    favorites: [],
    daily: { date: today, count: 0, learnedWords: [] },
    cursors: { everyday: 0, growing: 0, curious: 0 },
    rewards: [],
    activeTheme: "default",
    shields: 0,
    plus: false,
    awarded: {},
    quizAttempts: 0,
    testAttempts: 0,
    bestTest: null
  };
}

function normalizeProfile(profile) {
  return {
    ...makeProfile(profile.name || "Learner", profile.level || "everyday"),
    ...profile,
    daily: { date: dayKey(), count: 0, learnedWords: [], ...(profile.daily || {}) },
    cursors: { everyday: 0, growing: 0, curious: 0, ...(profile.cursors || {}) },
    learned: profile.learned || [],
    favorites: profile.favorites || [],
    rewards: profile.rewards || [],
    awarded: profile.awarded || {}
  };
}

function dayKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function dateDistance(fromKey, toKey) {
  const from = new Date(`${fromKey}T12:00:00`);
  const to = new Date(`${toKey}T12:00:00`);
  return Math.round((to - from) / 86400000);
}

function refreshDay(profile) {
  const today = dayKey();
  if (profile.daily.date !== today) {
    profile.daily = { date: today, count: 0, learnedWords: [] };
  }

  if (profile.lastActiveDay !== today) {
    const gap = dateDistance(profile.lastActiveDay, today);
    if (gap === 1) profile.streak += 1;
    else if (gap > 1 && profile.shields > 0) {
      profile.shields -= 1;
      profile.streak += 1;
      showToast("Your streak shield saved your streak ◆");
    } else if (gap > 1) profile.streak = 1;
    profile.lastActiveDay = today;
  }
}

function showAuth() {
  $("#app").hidden = true;
  $("#authScreen").hidden = false;
  const hasProfiles = profiles.length > 0;
  $("#profileChooser").hidden = !hasProfiles;
  $("#createProfileForm").hidden = hasProfiles;
  renderProfileChoices();
}

function renderProfileChoices() {
  const list = $("#profileList");
  list.textContent = "";
  profiles.forEach(profile => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "profile-choice";
    button.innerHTML = `<span>${escapeHTML(profile.name.slice(0, 1).toUpperCase())}</span><div><strong>${escapeHTML(profile.name)}</strong><small>${escapeHTML(LEVELS[profile.level]?.label || "Everyday")} · ${Number(profile.points || 0).toLocaleString()} points</small></div>`;
    button.addEventListener("click", () => signIn(profile.id));
    list.appendChild(button);
  });
}

async function signIn(profileId) {
  const found = profiles.find(profile => profile.id === profileId);
  if (!found) return;
  activeProfile = normalizeProfile(found);
  refreshDay(activeProfile);
  localStorage.setItem(ACTIVE_KEY, activeProfile.id);
  saveProfiles();
  document.body.dataset.theme = activeProfile.activeTheme === "default" ? "" : activeProfile.activeTheme;
  $("#authScreen").hidden = true;
  $("#app").hidden = false;
  renderAll();
  await loadNextWord(false);
}

function signOut() {
  saveProfiles();
  localStorage.removeItem(ACTIVE_KEY);
  activeProfile = null;
  currentWord = null;
  showAuth();
}

function renderAll() {
  if (!activeProfile) return;
  const initial = activeProfile.name.slice(0, 1).toUpperCase();
  $("#headerPoints").textContent = activeProfile.points.toLocaleString();
  $("#avatarButton").textContent = initial;
  $("#streakCount").textContent = activeProfile.streak;
  $("#learnedCount").textContent = activeProfile.learned.length;
  $("#profileAvatar").textContent = initial;
  $("#profileName").textContent = activeProfile.name;
  $("#profileLevel").textContent = `${LEVELS[activeProfile.level].label} level${activeProfile.rewards.includes("wordmaster") ? " · Word Master ★" : ""}`;
  $("#profileStreak").textContent = activeProfile.streak;
  $("#profileLearned").textContent = activeProfile.learned.length;
  $("#profilePoints").textContent = activeProfile.points.toLocaleString();
  $("#profileBest").textContent = activeProfile.bestTest === null ? "—" : `${activeProfile.bestTest}%`;
  $("#plusStatus").textContent = activeProfile.plus ? "Plus preview active · unlimited words" : "Free plan · 8 words each day";
  $("#profilePlusButton").textContent = activeProfile.plus ? "Plus active" : "See Plus";
  $("#plusBadge").hidden = !activeProfile.plus;
  $("#rewardPoints").textContent = activeProfile.points.toLocaleString();
  $$('[data-level]').forEach(button => {
    const selected = button.dataset.level === activeProfile.level;
    button.setAttribute("aria-pressed", String(selected));
  });
  const hour = new Date().getHours();
  $("#greeting").textContent = hour < 12 ? "GOOD MORNING" : hour < 18 ? "GOOD AFTERNOON" : "GOOD EVENING";
  renderDailyProgress();
  renderRewards();
  renderSavedWords();
  updateFavoriteButton();
}

function renderDailyProgress() {
  const count = Math.min(activeProfile.daily.count, 8);
  $("#dailyFraction").textContent = activeProfile.plus ? "∞" : `${count}/8`;
  $("#dailyTitle").textContent = activeProfile.plus ? "Unlimited words" : "Your daily eight";
  $("#dailyMessage").textContent = activeProfile.plus ? "Plus is active — there is no daily cap." : "Eight new chances to learn—every day.";
  $("#wordPosition").textContent = activeProfile.plus ? `UNLIMITED WORD ${activeProfile.daily.count + 1}` : `WORD ${Math.min(count + 1, 8)} OF 8`;
  const dots = $("#dailyDots");
  dots.textContent = "";
  for (let i = 0; i < 8; i += 1) {
    const dot = document.createElement("span");
    if (i < count) dot.className = "done";
    dots.appendChild(dot);
  }
  dots.setAttribute(
    "aria-label",
    activeProfile.plus
      ? `${count} words learned today; unlimited plan active`
      : `${count} of 8 daily words complete`,
  );
  const atLimit = activeProfile.daily.count >= 8 && !activeProfile.plus;
  $("#learnButton").innerHTML = atLimit ? "Continue with Plus <span>→</span>" : "I learned this <span>+10 ✦</span>";
}

function hashString(value) {
  let hash = 2166136261;
  for (let i = 0; i < value.length; i += 1) {
    hash ^= value.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function candidateAt(level, offset = 0) {
  const bank = window.EIGHT_WORDS_BANK?.[level] || [];
  if (!bank.length) return FALLBACK_WORDS.find(item => item.level === level)?.word || "wonder";
  const seed = hashString(`${dayKey()}:${activeProfile.id}:${level}`);
  const cursor = activeProfile.cursors[level] + offset;
  return bank[(seed + cursor * 7919) % bank.length];
}

async function fetchWord(word, level) {
  const normalized = word.toLowerCase().replace(/[^a-z]/g, "");
  if (!normalized) throw new Error("Invalid word");
  const bundled = window.EIGHT_WORDS_CATALOG?.[level]?.find(item => item.word === normalized);
  if (bundled) return { ...bundled };
  const first = normalized.slice(0, 1);
  const firstTwo = normalized.length === 1 ? first : normalized.slice(0, 2);
  const response = await fetch(`${REMOTE_DICTIONARY}/${first}/${firstTwo}.json`, { cache: "force-cache" });
  if (!response.ok) throw new Error("Definition unavailable");
  const group = await response.json();
  const entry = group[normalized];
  if (!entry?.etymologies) throw new Error("Definition unavailable");

  const choices = [];
  entry.etymologies.forEach(etymology => {
    (etymology.partsOfSpeech || []).forEach(part => {
      (part.senses || []).forEach(sense => {
        const definition = cleanText(sense.sense || "");
        const partName = String(part.partOfSpeech || "").toLowerCase();
        const learnerFriendlyPart = ["noun", "verb", "adjective", "adverb"].includes(partName);
        const isInflection = /\b(form of|plural of|comparative of|superlative of|participle of|third-person singular|simple past of)\b/i.test(definition);
        const unsuitable = /\b(offensive|vulgar|obsolete|archaic)\b/i.test(definition);
        if (learnerFriendlyPart && definition.length >= 18 && definition.length <= 260 && !isInflection && !unsuitable) {
          choices.push({
            partOfSpeech: partName,
            definition,
            example: cleanText((sense.examples || [])[0] || "")
          });
        }
      });
    });
  });
  if (!choices.length) throw new Error("Definition unavailable");
  const choice = choices.find(item => !/^\([^)]*(dated|archaic|slang)/i.test(item.definition)) || choices[0];
  return {
    word: normalized,
    pronunciation: normalized,
    partOfSpeech: choice.partOfSpeech,
    definition: choice.definition,
    example: choice.example || `Try using “${normalized}” in a sentence of your own.`,
    level,
    source: "Wiktionary"
  };
}

function cleanText(value) {
  const parser = new DOMParser();
  const documentFragment = parser.parseFromString(String(value), "text/html");
  return (documentFragment.body.textContent || "").replace(/\s+/g, " ").trim();
}

async function loadNextWord(advanceCursor = true) {
  if (!activeProfile) return;
  $("#wordLoading").hidden = false;
  $("#wordContent").hidden = true;
  $("#learnButton").disabled = true;

  let selected = null;
  let selectedOffset = 0;
  for (let attempt = 0; attempt < 10 && !selected; attempt += 1) {
    const candidate = candidateAt(activeProfile.level, attempt);
    try {
      selected = await fetchWord(candidate, activeProfile.level);
      selectedOffset = attempt;
    }
    catch { /* Try the next ranked word. */ }
  }

  if (!selected) {
    const localPool = FALLBACK_WORDS.filter(item => item.level === activeProfile.level);
    selected = { ...localPool[activeProfile.cursors[activeProfile.level] % localPool.length], pronunciation: "", source: "Eightwise" };
  }

  currentWord = selected;
  activeProfile.cursors[activeProfile.level] += selectedOffset + 1;
  saveProfiles();
  renderWord();
}

function renderWord() {
  if (!currentWord) return;
  $("#wordText").textContent = currentWord.word;
  $("#wordText").setAttribute("aria-expanded", "false");
  $("#syllablePanel").hidden = true;
  $("#partOfSpeech").textContent = currentWord.partOfSpeech || "word";
  $("#pronunciation").textContent = currentWord.pronunciation ? `/ ${currentWord.pronunciation} /` : "";
  $("#definitionText").textContent = currentWord.definition;
  $("#exampleText").textContent = currentWord.example;
  $("#wordSource").textContent = currentWord.source === "Open English WordNet 2025"
    ? "Definition source: Open English WordNet 2025 · CC BY 4.0"
    : currentWord.source === "Wiktionary"
      ? "Definition source: Wiktionary · CC BY-SA 3.0"
      : "Curated by Eightwise";
  $("#wordLoading").hidden = true;
  $("#wordContent").hidden = false;
  $("#learnButton").disabled = false;
  updateFavoriteButton();
  renderDailyProgress();
}

function updateFavoriteButton() {
  if (!activeProfile || !currentWord) return;
  const saved = activeProfile.favorites.some(item => item.word === currentWord.word);
  $("#favoriteButton").textContent = saved ? "♥" : "♡";
  $("#favoriteButton").setAttribute("aria-pressed", String(saved));
  $("#favoriteButton").setAttribute("aria-label", saved ? `Remove ${currentWord.word} from saved words` : `Save ${currentWord.word}`);
}

function toggleFavorite() {
  if (!currentWord) return;
  const index = activeProfile.favorites.findIndex(item => item.word === currentWord.word);
  if (index >= 0) {
    activeProfile.favorites.splice(index, 1);
    showToast(`${currentWord.word} removed from saved words`);
  } else {
    activeProfile.favorites.unshift({ ...currentWord });
    showToast(`${currentWord.word} saved for review ♥`);
  }
  saveProfiles();
  renderAll();
}

function renderSavedWords() {
  if (!activeProfile) return;
  const list = $("#savedWordsList");
  list.textContent = "";
  $("#savedWordCount").textContent = activeProfile.favorites.length;
  if (!activeProfile.favorites.length) {
    const empty = document.createElement("p");
    empty.className = "saved-empty";
    empty.textContent = "Tap the heart beside a word to save it here.";
    list.appendChild(empty);
    return;
  }
  activeProfile.favorites.forEach(item => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "saved-word-chip";
    button.textContent = item.word;
    button.addEventListener("click", () => {
      currentWord = item;
      renderWord();
      showView("learn");
    });
    list.appendChild(button);
  });
}

function syllabify(input) {
  const word = String(input || "").toLowerCase().replace(/[^a-z]/g, "");
  if (!word) return [];
  if (SYLLABLE_EXCEPTIONS[word]) return SYLLABLE_EXCEPTIONS[word];
  if (word.length <= 3) return [word];

  const vowels = "aeiouy";
  const diphthongs = new Set(["ai", "ay", "au", "aw", "ea", "ee", "ei", "ey", "eu", "ie", "oa", "oe", "oi", "oo", "ou", "ow", "ue", "ui"]);
  const nuclei = [];
  let index = 0;

  while (index < word.length) {
    if (!vowels.includes(word[index]) || (word[index] === "u" && index > 0 && word[index - 1] === "q")) {
      index += 1;
      continue;
    }
    const start = index;
    index += 1;
    while (index < word.length && vowels.includes(word[index])) {
      const pair = word.slice(index - 1, index + 1);
      if (pair === "io" && word[index + 1] === "n") index += 1;
      else if (diphthongs.has(pair)) index += 1;
      else break;
    }
    nuclei.push({ start, end: index - 1 });
  }

  const endsWithSyllabicLe = /[^aeiouy]le$/.test(word);
  if (nuclei.length > 1 && nuclei.at(-1).start === word.length - 1 && word.endsWith("e") && !endsWithSyllabicLe) nuclei.pop();
  if (nuclei.length <= 1) return [word];

  const onsetPairs = new Set(["bl", "br", "ch", "cl", "cr", "dr", "fl", "fr", "gl", "gr", "ph", "pl", "pr", "qu", "sh", "sl", "th", "tr", "tw", "wh", "wr"]);
  const boundaries = [];
  for (let i = 0; i < nuclei.length - 1; i += 1) {
    const previous = nuclei[i];
    const next = nuclei[i + 1];
    const clusterStart = previous.end + 1;
    const clusterEnd = next.start;
    const clusterLength = clusterEnd - clusterStart;
    let boundary;

    if (endsWithSyllabicLe && i === nuclei.length - 2) boundary = Math.max(clusterStart, word.length - 3);
    else if (clusterLength <= 1) boundary = clusterStart;
    else {
      const finalPair = word.slice(clusterEnd - 2, clusterEnd);
      boundary = onsetPairs.has(finalPair) ? clusterEnd - 2 : clusterEnd - 1;
    }
    boundaries.push(Math.max(1, boundary));
  }

  const pieces = [];
  let start = 0;
  [...new Set(boundaries)].sort((a, b) => a - b).forEach(boundary => {
    if (boundary > start) pieces.push(word.slice(start, boundary));
    start = boundary;
  });
  if (start < word.length) pieces.push(word.slice(start));
  return pieces.filter(Boolean);
}

function toggleSyllables() {
  if (!currentWord) return;
  const panel = $("#syllablePanel");
  const willShow = panel.hidden;
  panel.hidden = !willShow;
  $("#wordText").setAttribute("aria-expanded", String(willShow));
  if (!willShow) return;
  const syllables = syllabify(currentWord.word);
  $("#syllableText").textContent = syllables.join(" · ");
  $("#syllableCount").textContent = `${syllables.length} ${syllables.length === 1 ? "syllable" : "syllables"}`;
}

async function markCurrentWordLearned() {
  if (!activeProfile || !currentWord) return;
  if (activeProfile.daily.count >= 8 && !activeProfile.plus) {
    openModal("paywallModal");
    return;
  }

  const dailyWordKey = `${dayKey()}:${currentWord.word}`;
  if (!activeProfile.daily.learnedWords.includes(currentWord.word)) {
    activeProfile.daily.learnedWords.push(currentWord.word);
    activeProfile.daily.count += 1;
  }

  const learnedIndex = activeProfile.learned.findIndex(item => item.word === currentWord.word);
  const learnedRecord = { ...currentWord, lastSeen: dayKey() };
  if (learnedIndex >= 0) activeProfile.learned[learnedIndex] = learnedRecord;
  else activeProfile.learned.push(learnedRecord);

  awardOnce(`learn:${dailyWordKey}`, 10, "+10 points for a new word");
  if (activeProfile.daily.count === 8) awardOnce(`daily:${dayKey()}`, 50, "Daily eight complete · +50 points!");
  saveProfiles();
  renderAll();

  if (activeProfile.daily.count < 8 || activeProfile.plus) await loadNextWord(true);
}

function awardOnce(key, amount, message) {
  if (activeProfile.awarded[key]) return false;
  activeProfile.awarded[key] = true;
  activeProfile.points += amount;
  showToast(message);
  return true;
}

function showView(viewName) {
  currentView = viewName;
  $$(".view").forEach(view => view.classList.toggle("active", view.dataset.view === viewName));
  $$(".bottom-nav button").forEach(button => button.classList.toggle("active", button.dataset.viewTarget === viewName));
  if (viewName === "rewards") renderRewards();
  if (viewName === "profile") renderAll();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function practicePool() {
  const records = [...activeProfile.learned, ...activeProfile.favorites, ...FALLBACK_WORDS];
  const seen = new Set();
  return records.filter(record => {
    const valid = record.word && record.definition && !seen.has(record.word);
    seen.add(record.word);
    return valid;
  });
}

function buildQuestions(count, mode) {
  const pool = shuffle(practicePool());
  const chosen = pool.slice(0, Math.min(count, pool.length));
  return chosen.map((entry, index) => {
    const asksForWord = mode === "test" && index % 2 === 0;
    const distractors = shuffle(pool.filter(item => item.word !== entry.word)).slice(0, 3);
    return {
      entry,
      asksForWord,
      prompt: asksForWord ? entry.definition : entry.word,
      options: shuffle([entry, ...distractors])
    };
  });
}

function startQuiz() {
  quizSession = { questions: buildQuestions(5, "quiz"), index: 0, score: 0, answered: false };
  activeProfile.quizAttempts += 1;
  saveProfiles();
  $("#quizIntro").hidden = true;
  $("#quizResult").hidden = true;
  $("#quizGame").hidden = false;
  renderQuizQuestion();
}

function renderQuizQuestion() {
  const session = quizSession;
  const question = session.questions[session.index];
  $("#quizProgress").textContent = `${session.index + 1} / ${session.questions.length}`;
  $("#quizWord").textContent = question.entry.word;
  renderAnswers($("#quizOptions"), question, false, answerQuiz);
  $("#quizNextButton").hidden = true;
  session.answered = false;
}

function answerQuiz(selectedWord, buttons) {
  if (quizSession.answered) return;
  quizSession.answered = true;
  const question = quizSession.questions[quizSession.index];
  const correct = selectedWord === question.entry.word;
  if (correct) {
    quizSession.score += 1;
    awardOnce(`quiz:${dayKey()}:${question.entry.word}`, 20, "Correct · +20 points");
  }
  markAnswers(buttons, selectedWord, question.entry.word);
  saveProfiles(); renderAll();
  $("#quizNextButton").hidden = false;
}

function nextQuizQuestion() {
  quizSession.index += 1;
  if (quizSession.index < quizSession.questions.length) renderQuizQuestion();
  else finishQuiz();
}

function finishQuiz() {
  $("#quizGame").hidden = true;
  const result = $("#quizResult");
  result.hidden = false;
  const percent = Math.round((quizSession.score / quizSession.questions.length) * 100);
  result.innerHTML = `<div class="score-ring">${percent}%</div><h2>${quizSession.score >= 4 ? "Great work!" : "Nice practice!"}</h2><p>You answered ${quizSession.score} of ${quizSession.questions.length} correctly.</p><button class="button button-primary" type="button" id="quizAgainButton">Try another quiz</button>`;
  $("#quizAgainButton").addEventListener("click", startQuiz);
}

function startTest() {
  testSession = { questions: buildQuestions(10, "test"), index: 0, score: 0, answered: false };
  activeProfile.testAttempts += 1;
  saveProfiles();
  $("#testIntro").hidden = true;
  $("#testResult").hidden = true;
  $("#testGame").hidden = false;
  renderTestQuestion();
}

function renderTestQuestion() {
  const session = testSession;
  const question = session.questions[session.index];
  $("#testProgress").textContent = `${session.index + 1} / ${session.questions.length}`;
  $("#testPromptLabel").textContent = question.asksForWord ? "CHOOSE THE WORD" : "CHOOSE THE MEANING";
  $("#testPrompt").textContent = question.prompt;
  renderAnswers($("#testOptions"), question, question.asksForWord, answerTest);
  $("#testNextButton").hidden = true;
  session.answered = false;
}

function answerTest(selectedWord, buttons) {
  if (testSession.answered) return;
  testSession.answered = true;
  const question = testSession.questions[testSession.index];
  const correct = selectedWord === question.entry.word;
  if (correct) {
    testSession.score += 1;
    awardOnce(`test:${dayKey()}:${question.entry.word}`, 15, "Correct · +15 points");
  }
  markAnswers(buttons, selectedWord, question.entry.word);
  saveProfiles(); renderAll();
  $("#testNextButton").hidden = false;
}

function nextTestQuestion() {
  testSession.index += 1;
  if (testSession.index < testSession.questions.length) renderTestQuestion();
  else finishTest();
}

function finishTest() {
  $("#testGame").hidden = true;
  const result = $("#testResult");
  result.hidden = false;
  const percent = Math.round((testSession.score / testSession.questions.length) * 100);
  activeProfile.bestTest = Math.max(activeProfile.bestTest || 0, percent);
  if (percent === 100) awardOnce(`perfect:${dayKey()}`, 100, "Perfect test · +100 bonus points!");
  saveProfiles(); renderAll();
  result.innerHTML = `<div class="score-ring">${percent}%</div><h2>${percent === 100 ? "Perfect score!" : percent >= 80 ? "Excellent!" : "Keep growing!"}</h2><p>You answered ${testSession.score} of ${testSession.questions.length} correctly.</p><button class="button button-primary" type="button" id="testAgainButton">Take another test</button>`;
  $("#testAgainButton").addEventListener("click", startTest);
}

function renderAnswers(container, question, showWords, handler) {
  container.textContent = "";
  question.options.forEach(option => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "answer";
    button.dataset.word = option.word;
    button.textContent = showWords ? option.word : option.definition;
    button.addEventListener("click", () => handler(option.word, [...container.querySelectorAll("button")]));
    container.appendChild(button);
  });
}

function markAnswers(buttons, selectedWord, correctWord) {
  buttons.forEach(button => {
    button.disabled = true;
    if (button.dataset.word === correctWord) button.classList.add("correct");
    else if (button.dataset.word === selectedWord) button.classList.add("wrong");
  });
}

function shuffle(items) {
  const copy = [...items];
  for (let index = copy.length - 1; index > 0; index -= 1) {
    const swap = Math.floor(Math.random() * (index + 1));
    [copy[index], copy[swap]] = [copy[swap], copy[index]];
  }
  return copy;
}

function renderRewards() {
  if (!activeProfile) return;
  const grid = $("#rewardGrid");
  grid.textContent = "";
  $("#rewardPoints").textContent = activeProfile.points.toLocaleString();
  REWARDS.forEach(reward => {
    const owned = activeProfile.rewards.includes(reward.id);
    const active = reward.kind === "theme" && activeProfile.activeTheme === reward.value;
    const card = document.createElement("article");
    card.className = `reward-card${owned ? " owned" : ""}`;
    card.innerHTML = `<div class="reward-icon">${reward.icon}</div><h3>${escapeHTML(reward.name)}</h3><p>${escapeHTML(reward.description)}</p><button class="button button-primary" type="button">${active ? "Using now ✓" : owned && reward.kind === "theme" ? "Use theme" : owned ? "Owned ✓" : `${reward.cost.toLocaleString()} points`}</button>`;
    const button = card.querySelector("button");
    button.disabled = active || (owned && reward.kind !== "theme");
    button.addEventListener("click", () => redeemReward(reward));
    grid.appendChild(card);
  });
}

function redeemReward(reward) {
  const owned = activeProfile.rewards.includes(reward.id);
  if (owned && reward.kind === "theme") {
    activeProfile.activeTheme = reward.value;
    document.body.dataset.theme = reward.value;
    saveProfiles(); renderRewards();
    showToast(`${reward.name} is active`);
    return;
  }
  if (owned) return;
  if (activeProfile.points < reward.cost) {
    showToast(`You need ${(reward.cost - activeProfile.points).toLocaleString()} more points`);
    return;
  }
  activeProfile.points -= reward.cost;
  activeProfile.rewards.push(reward.id);
  if (reward.kind === "theme") {
    activeProfile.activeTheme = reward.value;
    document.body.dataset.theme = reward.value;
  }
  if (reward.kind === "shield") activeProfile.shields += 1;
  saveProfiles(); renderAll();
  showToast(`${reward.name} unlocked!`);
}

function openModal(id) {
  const modal = document.getElementById(id);
  modal.hidden = false;
  modal.querySelector("button")?.focus();
}

function closeModal(id) {
  document.getElementById(id).hidden = true;
}

function showToast(message) {
  const toast = $("#toast");
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("show"), 2400);
}

function escapeHTML(value) {
  return String(value).replace(/[&<>"]/g, character => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[character]);
}

function bindEvents() {
  $("#createProfileForm").addEventListener("submit", event => {
    event.preventDefault();
    const name = $("#displayName").value.trim();
    if (!name) return;
    const profile = makeProfile(name, $("#startingLevel").value);
    profiles.push(profile);
    saveProfiles();
    signIn(profile.id);
  });

  $("#showCreateButton").addEventListener("click", () => {
    $("#profileChooser").hidden = true;
    $("#createProfileForm").hidden = false;
    $("#displayName").focus();
  });

  $$('[data-view-target]').forEach(button => button.addEventListener("click", () => showView(button.dataset.viewTarget)));
  $$('[data-close-modal]').forEach(element => element.addEventListener("click", () => closeModal(element.dataset.closeModal)));
  $$('[data-level]').forEach(button => button.addEventListener("click", async () => {
    if (button.dataset.level === activeProfile.level) return;
    activeProfile.level = button.dataset.level;
    saveProfiles(); renderAll();
    await loadNextWord(false);
  }));
  $("#learnButton").addEventListener("click", markCurrentWordLearned);
  $("#wordText").addEventListener("click", toggleSyllables);
  $("#favoriteButton").addEventListener("click", toggleFavorite);
  $("#speakButton").addEventListener("click", () => {
    if (!currentWord || !("speechSynthesis" in window)) return;
    speechSynthesis.cancel();
    const speech = new SpeechSynthesisUtterance(currentWord.word);
    speech.rate = .82;
    speech.lang = "en-US";
    speechSynthesis.speak(speech);
  });
  $("#startQuizButton").addEventListener("click", startQuiz);
  $("#quizNextButton").addEventListener("click", nextQuizQuestion);
  $("#startTestButton").addEventListener("click", startTest);
  $("#testNextButton").addEventListener("click", nextTestQuestion);
  $("#signOutButton").addEventListener("click", signOut);
  $("#profilePlusButton").addEventListener("click", () => openModal("paywallModal"));
  $("#surpriseWordButton").addEventListener("click", async () => {
    if (!activeProfile.plus) {
      openModal("paywallModal");
      return;
    }
    const bank = window.EIGHT_WORDS_BANK?.[activeProfile.level] || [];
    activeProfile.cursors[activeProfile.level] = Math.floor(Math.random() * Math.max(bank.length, 1));
    saveProfiles();
    showView("learn");
    showToast("Here is a surprise word ✦");
    await loadNextWord(false);
  });
  $("#previewPlusButton").addEventListener("click", async () => {
    activeProfile.plus = true;
    saveProfiles(); renderAll(); closeModal("paywallModal");
    showToast("Plus preview is active on this profile");
    await loadNextWord(true);
  });
}

async function initialize() {
  bindEvents();
  const activeId = localStorage.getItem(ACTIVE_KEY);
  if (activeId && profiles.some(profile => profile.id === activeId)) await signIn(activeId);
  else showAuth();

  if ("serviceWorker" in navigator && location.protocol.startsWith("http")) {
    navigator.serviceWorker.register("service-worker.js").catch(() => {});
  }
}

initialize();
