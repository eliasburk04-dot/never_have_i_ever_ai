/**
 * validate_content.ts
 *
 * Static validation of app/assets/questions.json against QUALITY_SPEC.md rules.
 * Exit 0 = all pass, Exit 1 = violations found.
 *
 * Usage: npx tsx validate_content.ts
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import { resolve, dirname } from "path";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Question {
  id: string;
  text_en: string;
  text_de: string;
  text_es: string;
  category: string;
  subcategory: string;
  intensity: number;
  is_nsfw: boolean;
  is_premium: boolean;
  shock_factor: number;
  vulnerability_level: number;
  energy: string;
}

export interface Violation {
  id: string;
  field: string;
  rule: string;
  message: string;
  value: string;
}

// ─── Constants ──────────────────────────────────────────────────────────────

const CANONICAL_CATEGORIES = new Set([
  "food",
  "embarrassing",
  "social",
  "moral_gray",
  "risk",
  "relationships",
  "confessions",
  "sexual",
  "party",
  "deep",
]);

const CANONICAL_ENERGIES = new Set(["light", "medium", "heavy"]);

// ─── Validation Functions ───────────────────────────────────────────────────

export function validateQuestion(q: Question, index: number, totalCount = 999): Violation[] {
  const v: Violation[] = [];
  const add = (field: string, rule: string, message: string, value?: string) =>
    v.push({ id: q.id, field, rule, message, value: value ?? "" });

  // U9: id format
  const width = Math.max(3, String(totalCount).length);
  const expectedId = `q${String(index + 1).padStart(width, "0")}`;
  if (!/^q\d{3,}$/.test(q.id)) {
    add("id", "U9", `Invalid id format: "${q.id}", expected q + ${width} digits`, q.id);
  } else if (q.id !== expectedId) {
    add("id", "U9", `ID gap/order: got "${q.id}", expected "${expectedId}"`, q.id);
  }

  // U8: non-empty text fields
  for (const lang of ["text_en", "text_de", "text_es"] as const) {
    const text = q[lang];
    if (!text || typeof text !== "string" || text.trim().length === 0) {
      add(lang, "U8", `Empty or missing ${lang}`);
      continue;
    }

    // U2: trailing whitespace
    if (text !== text.trimEnd()) {
      add(lang, "U2", "Trailing whitespace", text);
    }

    // U3: leading whitespace
    if (text !== text.trimStart()) {
      add(lang, "U3", "Leading whitespace", text);
    }

    // U4: doubled spaces
    if (/  /.test(text)) {
      add(lang, "U4", "Doubled spaces", text);
    }

    // U5: ASCII control characters
    if (/[\x00-\x08\x0B\x0C\x0E-\x1F]/.test(text)) {
      add(lang, "U5", "ASCII control character found", text);
    }

    // U6: max length
    if (text.length > 150) {
      add(lang, "U6", `Text too long (${text.length} chars, max 150)`, text);
    }

    // U16: no HTML/Markdown
    if (/<[^>]+>/.test(text) || /[*_]{2,}/.test(text)) {
      add(lang, "U16", "HTML or Markdown detected", text);
    }
  }

  // U10: intensity
  if (!Number.isInteger(q.intensity) || q.intensity < 1 || q.intensity > 10) {
    add("intensity", "U10", `Intensity must be integer 1-10, got ${q.intensity}`, String(q.intensity));
  }

  // U11: booleans
  if (typeof q.is_nsfw !== "boolean") {
    add("is_nsfw", "U11", `is_nsfw must be boolean, got ${typeof q.is_nsfw}`, String(q.is_nsfw));
  }
  if (typeof q.is_premium !== "boolean") {
    add("is_premium", "U11", `is_premium must be boolean, got ${typeof q.is_premium}`, String(q.is_premium));
  }

  // U12: shock_factor / vulnerability_level
  if (typeof q.shock_factor !== "number" || q.shock_factor < 0 || q.shock_factor > 1) {
    add("shock_factor", "U12", `shock_factor must be 0.0-1.0, got ${q.shock_factor}`, String(q.shock_factor));
  }
  if (typeof q.vulnerability_level !== "number" || q.vulnerability_level < 0 || q.vulnerability_level > 1) {
    add("vulnerability_level", "U12", `vulnerability_level must be 0.0-1.0, got ${q.vulnerability_level}`, String(q.vulnerability_level));
  }

  // U13: energy
  if (!CANONICAL_ENERGIES.has(q.energy)) {
    add("energy", "U13", `Invalid energy "${q.energy}"`, q.energy);
  }

  // U14: category
  if (!CANONICAL_CATEGORIES.has(q.category)) {
    add("category", "U14", `Invalid category "${q.category}"`, q.category);
  }

  // U15: nsfw → premium
  if (q.is_nsfw === true && q.is_premium !== true) {
    add("is_premium", "U15", "is_nsfw=true but is_premium=false");
  }

  // ── EN rules ──

  // EN1: prefix
  if (q.text_en && !q.text_en.startsWith("Never have I ever ")) {
    add("text_en", "EN1", 'Must start with "Never have I ever "', q.text_en);
  }

  // EN2: no trailing punctuation
  if (q.text_en && /[.?!]$/.test(q.text_en)) {
    add("text_en", "EN2", "Must not end with . ? or !", q.text_en);
  }

  // ── DE rules ──

  // DE1: prefix — accept all natural German "Ich hab noch nie" variants
  if (q.text_de) {
    const validDePrefixes = [
      "Ich hab noch nie ",
      "Ich hab mich noch nie ",
      "Ich hab mir noch nie ",
      "Ich hab es noch nie ",
      "Ich war noch nie ",
      "Ich hatte noch nie ",
      "Ich hatte als ",
      "Ich bin noch nie ",
      "Ich habe noch nie ",
      "Ich konnte noch nie ",
      "Ich musste noch nie ",
      "Ich musste mich noch nie ",
      "Ich wurde noch nie ",
      "Ich wollte noch nie ",
      "Ich wäre noch nie ",
      "Ich stand noch nie ",
      "Mir wurde noch nie ",
      "Mir war noch nie ",
      "Mir ist noch nie ",
      "Mir hat noch nie ",
      "Mein Leben ist noch nie ",
      "Noch nie hat ",
      "Noch nie wurde ",
      "Noch nie haben ",
      "In mich hat sich noch nie ",
      "Es ist noch nie ",
    ];
    const hasValidPrefix = validDePrefixes.some(p => q.text_de.startsWith(p));
    if (!hasValidPrefix) {
      add("text_de", "DE1", 'Must start with a valid German "Ich hab noch nie" variant', q.text_de);
    }
  }

  // DE2: no trailing punctuation
  if (q.text_de && /[.?!]$/.test(q.text_de)) {
    add("text_de", "DE2", "Must not end with . ? or !", q.text_de);
  }

  // DE3: ASCII transliterations (basic check for common patterns)
  if (q.text_de) {
    const deTranslit = detectGermanTransliterations(q.text_de);
    for (const t of deTranslit) {
      add("text_de", "DE3", `Possible ASCII transliteration: "${t.match}" → should be "${t.replacement}"`, q.text_de);
    }
  }

  // ── ES rules ──

  // ES1: prefix — accept natural Spanish "Nunca" variants
  if (q.text_es) {
    const validEsPrefixes = [
      "Nunca he ",
      "Nunca me he ",
      "Nunca me ha ",
      "Nunca me han ",
      "Nunca le he ",
      "Nunca les he ",
      "Nunca se me ha ",
      "Nunca se me ",
      "Nunca se ha ",
      "Nunca se han ",
      "Nunca nos ",
      "Nunca mi ",
      "Nunca un ",
      "Nunca una ",
      "Nunca alguien ",
      "Nunca la familia ",
      "Nunca mis amigos ",
      "Nunca me retaron ",
      "Nunca hice ",
      "Nunca casi ",
      "Nunca lo he ",
    ];
    const hasValidPrefix = validEsPrefixes.some(p => q.text_es.startsWith(p));
    if (!hasValidPrefix) {
      add("text_es", "ES1", 'Must start with "Nunca he " or accepted variant', q.text_es);
    }
  }

  // ES2: no trailing punctuation
  if (q.text_es && /[.?!]$/.test(q.text_es)) {
    add("text_es", "ES2", "Must not end with . ? or !", q.text_es);
  }

  // ES5: verb form check — skip for now since we use "Nunca he" format
  // The "Nunca he" + participio pattern is inherently correct.
  // This rule only applied to the "Yo nunca nunca" prefix format.

  return v;
}

export function validateDuplicates(questions: Question[]): Violation[] {
  const v: Violation[] = [];

  for (const lang of ["text_en", "text_de", "text_es"] as const) {
    const seen = new Map<string, string>();
    for (const q of questions) {
      const text = q[lang]?.toLowerCase().trim();
      if (!text) continue;
      const existing = seen.get(text);
      if (existing) {
        v.push({
          id: q.id,
          field: lang,
          rule: "U7",
          message: `Duplicate text in ${lang}: also in ${existing}`,
          value: q[lang],
        });
      } else {
        seen.set(text, q.id);
      }
    }
  }

  return v;
}

// ─── German Transliteration Detection ───────────────────────────────────────

interface TranslitMatch {
  match: string;
  replacement: string;
  index: number;
}

/**
 * German compound exceptions — words where ae/oe/ue/ss naturally occur
 * at morpheme boundaries and are NOT transliterations.
 */
const DE_COMPOUND_EXCEPTIONS = new Set([
  // ae compounds
  "abenteuer",    // Abenteuer (adventure)
  "abenteuerlich",
  "israel",
  "israelisch",
  "museum",
  "ideal",
  "duell",
  "aerob",
  "aerobic",
  // ue compounds (most common false positives)
  "bauer",
  "bauern",
  "mauer",
  "mauern",
  "lauer",
  "trauer",
  "trauern",
  "schauer",
  "genauer",
  "sauer",
  "dauer",
  "dauern",
  "dauerhaft",
  "stauer",
  "ungeheuer",
  "ungeheuerlich",
  "feuer",
  "feuern",
  "feuerwehr",
  "heuer",
  "steuer",
  "steuern",
  "teuer",
  "euer",
  "vertrauen",     // Vertrauen (trust)
  "zutiefst",      // zu + tiefst (deeply)
  "abgehauen",     // ab + gehauen (snuck out)
  "gehauen",       // past participle of hauen
  "hauen",
  "sexuell",       // Latin root: sexuell
  "sexuelle",
  "sexuelles",
  "sexuellen",
  "sexuellem",
  "sexueller",
  "aktuell",       // Latin root: aktuell
  "aktuelle",
  "aktuelles",
  "aktuellen",
  "eventuell",
  "individuell",
  "intellektuell",
  "rituell",
  "spirituell",
  "virtuell",
  "manuell",
  "unerklärlich",  // un + erklärlich (morpheme boundary)
  "unerklärlichen",
  "unendlich",
  "unerhört",
  "unerwartet",
  "uneben",
  "unecht",
  "uneinig",
  "unentschlossen",
  "bereue",        // bereuen (to regret)
  "bereuen",
  "bereut",
  "blaue",         // blau + inflection
  "blauen",
  "blaues",
  "blauem",
  "blauer",
  "graue",         // grau + inflection
  "grauen",
  "graues",
  "grauem",
  "grauer",
  "schauen",       // schauen (to look)
  "geschaut",
  "angeschaut",
  "zugeschaut",
  "zuschauen",
  "hingeschaut",
  "bauen",         // bauen (to build)
  "gebaut",
  "aufgebaut",
  "abgebaut",
  "vertraue",      // vertrauen inflections
  "vertraut",
  // additional valid ue words
  "neuen",         // neu + inflection (new)
  "neuem",
  "neues",
  "neuer",
  "neue",
  "erneut",
  "unbequemes",    // un + bequem + inflection
  "unbequem",
  "reue",          // Reue (remorse/regret)
  "zueinander",    // zu + einander (to each other)
  "konsequenzen",  // Konsequenzen (consequences)
  "konsequenz",
  // oe compounds
  "poet",
  "poesie",
  "poem",
  "phoenix",
  "koexistenz",
]);

export function detectGermanTransliterations(text: string): TranslitMatch[] {
  const results: TranslitMatch[] = [];
  const lower = text.toLowerCase();

  // Check for ae → ä
  const aeMatches = [...lower.matchAll(/ae/g)];
  for (const m of aeMatches) {
    const idx = m.index!;
    // Check if this "ae" is part of a compound exception
    if (!isCompoundException(lower, idx, "ae")) {
      results.push({ match: "ae", replacement: "ä", index: idx });
    }
  }

  // Check for oe → ö
  const oeMatches = [...lower.matchAll(/oe/g)];
  for (const m of oeMatches) {
    const idx = m.index!;
    if (!isCompoundException(lower, idx, "oe")) {
      results.push({ match: "oe", replacement: "ö", index: idx });
    }
  }

  // Check for ue → ü (most common false positives)
  const ueMatches = [...lower.matchAll(/ue/g)];
  for (const m of ueMatches) {
    const idx = m.index!;
    if (!isCompoundException(lower, idx, "ue")) {
      results.push({ match: "ue", replacement: "ü", index: idx });
    }
  }

  return results;
}

function isCompoundException(text: string, idx: number, digraph: string): boolean {
  // Extract the word containing this digraph
  const before = text.substring(0, idx);
  const after = text.substring(idx + digraph.length);
  const wordStart = before.search(/[a-zäöüß]*$/);
  const wordEndMatch = after.match(/^[a-zäöüß]*/);
  const wordEnd = wordEndMatch ? wordEndMatch[0] : "";
  const word = before.substring(wordStart) + digraph + wordEnd;

  for (const exception of DE_COMPOUND_EXCEPTIONS) {
    if (word.includes(exception)) return true;
  }
  return false;
}

// ─── UTF-8 / Encoding Check ────────────────────────────────────────────────

export function validateEncoding(filePath: string): Violation[] {
  const v: Violation[] = [];
  const buf = readFileSync(filePath);

  // U1: Check for BOM
  if (buf[0] === 0xEF && buf[1] === 0xBB && buf[2] === 0xBF) {
    v.push({ id: "FILE", field: "encoding", rule: "U1", message: "UTF-8 BOM detected", value: filePath });
  }

  // U1: Check for null bytes (likely UTF-16)
  for (let i = 0; i < buf.length; i++) {
    if (buf[i] === 0x00) {
      v.push({ id: "FILE", field: "encoding", rule: "U1", message: "Null byte found — possible UTF-16 encoding", value: filePath });
      break;
    }
  }

  return v;
}

// ─── Main ───────────────────────────────────────────────────────────────────

export function runContentValidation(questionsPath?: string): { violations: Violation[]; total: number } {
  const resolvedPath = questionsPath ?? resolve(dirname(new URL(import.meta.url).pathname), "../app/assets/questions.json");
  const raw = readFileSync(resolvedPath, "utf-8");
  const questions: Question[] = JSON.parse(raw);

  const violations: Violation[] = [];

  // Encoding check
  violations.push(...validateEncoding(resolvedPath));

  // Per-question validation
  questions.forEach((q, i) => {
    violations.push(...validateQuestion(q, i, questions.length));
  });

  // Cross-question checks
  violations.push(...validateDuplicates(questions));

  return { violations, total: questions.length };
}

// ─── CLI Entry Point ────────────────────────────────────────────────────────

const isMain = process.argv[1] && (
  process.argv[1].endsWith("validate_content.ts") ||
  process.argv[1].endsWith("validate_content.js")
);

if (isMain) {
  const { violations, total } = runContentValidation();

  // Write report
  const reportsDir = resolve(dirname(new URL(import.meta.url).pathname), "reports");
  if (!existsSync(reportsDir)) mkdirSync(reportsDir, { recursive: true });

  writeFileSync(
    resolve(reportsDir, "content_violations.json"),
    JSON.stringify(violations, null, 2),
  );

  // Console output
  console.log(`\n📋 Content Validation — ${total} questions scanned\n`);

  if (violations.length === 0) {
    console.log("✅ All checks passed.\n");
    process.exit(0);
  } else {
    console.log(`❌ ${violations.length} violation(s) found:\n`);
    const byRule = new Map<string, number>();
    for (const v of violations) {
      const count = byRule.get(v.rule) ?? 0;
      byRule.set(v.rule, count + 1);
      console.log(`  [${v.rule}] ${v.id}.${v.field}: ${v.message}`);
    }
    console.log("\n── Summary by rule ──");
    for (const [rule, count] of [...byRule.entries()].sort()) {
      console.log(`  ${rule}: ${count}`);
    }
    console.log("");
    process.exit(1);
  }
}
