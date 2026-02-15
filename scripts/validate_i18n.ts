/**
 * validate_i18n.ts
 *
 * Validates ARB localization files against QUALITY_SPEC.md rules (§6).
 * Exit 0 = all pass, Exit 1 = violations found.
 *
 * Usage: npx tsx validate_i18n.ts
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import { resolve, dirname } from "path";

// ─── Types ──────────────────────────────────────────────────────────────────

export interface I18nViolation {
  file: string;
  key: string;
  rule: string;
  message: string;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function isMetaKey(key: string): boolean {
  return key === "@@locale" || key.startsWith("@");
}

function extractPlaceholders(value: string): string[] {
  const matches = value.match(/\{[^}]+\}/g);
  return matches ? matches.sort() : [];
}

// ─── German transliteration patterns (same as validate_content) ─────────

const DE_COMPOUND_EXCEPTIONS = new Set([
  "abenteuer", "abenteuerlich", "israel", "israelisch", "museum", "ideal",
  "duell", "aerob", "aerobic",
  "bauer", "bauern", "mauer", "mauern", "lauer", "trauer", "trauern",
  "schauer", "genauer", "sauer", "dauer", "dauern", "dauerhaft", "stauer",
  "ungeheuer", "ungeheuerlich",
  "feuer", "feuern", "feuerwehr", "heuer", "steuer", "steuern", "teuer", "euer",
  "vertrauen", "zutiefst", "abgehauen", "gehauen", "hauen",
  "sexuell", "sexuelle", "sexuelles", "sexuellen", "sexuellem", "sexueller",
  "aktuell", "aktuelle", "aktuelles", "aktuellen",
  "eventuell", "individuell", "intellektuell", "rituell",
  "spirituell", "virtuell", "manuell",
  "unerklärlich", "unerklärlichen", "unendlich", "unerhört",
  "unerwartet", "uneben", "unecht", "uneinig", "unentschlossen",
  "bereue", "bereuen", "bereut",
  "blaue", "blauen", "blaues", "blauem", "blauer",
  "graue", "grauen", "graues", "grauem", "grauer",
  "schauen", "geschaut", "angeschaut", "zugeschaut", "zuschauen", "hingeschaut",
  "bauen", "gebaut", "aufgebaut", "abgebaut",
  "vertraue", "vertraut",
  "poet", "poesie", "poem", "phoenix", "koexistenz",
]);

function hasGermanTransliteration(text: string): string[] {
  const lower = text.toLowerCase();
  const found: string[] = [];

  for (const digraph of ["ae", "oe", "ue"]) {
    const regex = new RegExp(digraph, "g");
    let match: RegExpExecArray | null;
    while ((match = regex.exec(lower)) !== null) {
      // Extract the word
      const idx = match.index;
      const before = lower.substring(0, idx);
      const after = lower.substring(idx + digraph.length);
      const wordStart = before.search(/[a-zäöüß]*$/);
      const wordEndMatch = after.match(/^[a-zäöüß]*/);
      const wordEnd = wordEndMatch ? wordEndMatch[0] : "";
      const word = before.substring(wordStart) + digraph + wordEnd;

      let isException = false;
      for (const exc of DE_COMPOUND_EXCEPTIONS) {
        if (word.includes(exc)) {
          isException = true;
          break;
        }
      }
      if (!isException) {
        const replacement = digraph === "ae" ? "ä" : digraph === "oe" ? "ö" : "ü";
        found.push(`"${digraph}" → "${replacement}" in "${word}"`);
      }
    }
  }
  return found;
}

// ─── Validation ─────────────────────────────────────────────────────────────

export function validateArbFiles(l10nDir?: string): I18nViolation[] {
  const dir = l10nDir ?? resolve(dirname(new URL(import.meta.url).pathname), "../app/lib/l10n");

  const violations: I18nViolation[] = [];

  // ARB6: All files must be valid JSON
  let enData: Record<string, string>;
  let deData: Record<string, string>;
  let esData: Record<string, string>;

  try {
    enData = JSON.parse(readFileSync(resolve(dir, "app_en.arb"), "utf-8"));
  } catch (e) {
    violations.push({ file: "app_en.arb", key: "*", rule: "ARB6", message: `Invalid JSON: ${e}` });
    return violations;
  }
  try {
    deData = JSON.parse(readFileSync(resolve(dir, "app_de.arb"), "utf-8"));
  } catch (e) {
    violations.push({ file: "app_de.arb", key: "*", rule: "ARB6", message: `Invalid JSON: ${e}` });
    return violations;
  }
  try {
    esData = JSON.parse(readFileSync(resolve(dir, "app_es.arb"), "utf-8"));
  } catch (e) {
    violations.push({ file: "app_es.arb", key: "*", rule: "ARB6", message: `Invalid JSON: ${e}` });
    return violations;
  }

  // ARB7: @@locale must match
  if (enData["@@locale"] !== "en") {
    violations.push({ file: "app_en.arb", key: "@@locale", rule: "ARB7", message: `Expected "en", got "${enData["@@locale"]}"` });
  }
  if (deData["@@locale"] !== "de") {
    violations.push({ file: "app_de.arb", key: "@@locale", rule: "ARB7", message: `Expected "de", got "${deData["@@locale"]}"` });
  }
  if (esData["@@locale"] !== "es") {
    violations.push({ file: "app_es.arb", key: "@@locale", rule: "ARB7", message: `Expected "es", got "${esData["@@locale"]}"` });
  }

  // Collect non-meta keys from EN as the source of truth
  const enKeys = Object.keys(enData).filter((k) => !isMetaKey(k));
  const deKeys = new Set(Object.keys(deData).filter((k) => !isMetaKey(k)));
  const esKeys = new Set(Object.keys(esData).filter((k) => !isMetaKey(k)));

  // ARB1: Every EN key must exist in DE and ES
  for (const key of enKeys) {
    if (!deKeys.has(key)) {
      violations.push({ file: "app_de.arb", key, rule: "ARB1", message: `Missing key "${key}" (present in EN)` });
    }
    if (!esKeys.has(key)) {
      violations.push({ file: "app_es.arb", key, rule: "ARB1", message: `Missing key "${key}" (present in EN)` });
    }
  }

  // ARB2: No extra non-meta keys in DE/ES
  const enKeySet = new Set(enKeys);
  for (const key of deKeys) {
    if (!enKeySet.has(key)) {
      violations.push({ file: "app_de.arb", key, rule: "ARB2", message: `Extra key "${key}" not in EN` });
    }
  }
  for (const key of esKeys) {
    if (!enKeySet.has(key)) {
      violations.push({ file: "app_es.arb", key, rule: "ARB2", message: `Extra key "${key}" not in EN` });
    }
  }

  // ARB3: Placeholder parity
  for (const key of enKeys) {
    const enPlaceholders = extractPlaceholders(enData[key] || "");
    if (enPlaceholders.length === 0) continue;

    if (deKeys.has(key)) {
      const dePlaceholders = extractPlaceholders(deData[key] || "");
      if (JSON.stringify(enPlaceholders) !== JSON.stringify(dePlaceholders)) {
        violations.push({
          file: "app_de.arb",
          key,
          rule: "ARB3",
          message: `Placeholder mismatch: EN has ${JSON.stringify(enPlaceholders)}, DE has ${JSON.stringify(dePlaceholders)}`,
        });
      }
    }
    if (esKeys.has(key)) {
      const esPlaceholders = extractPlaceholders(esData[key] || "");
      if (JSON.stringify(enPlaceholders) !== JSON.stringify(esPlaceholders)) {
        violations.push({
          file: "app_es.arb",
          key,
          rule: "ARB3",
          message: `Placeholder mismatch: EN has ${JSON.stringify(enPlaceholders)}, ES has ${JSON.stringify(esPlaceholders)}`,
        });
      }
    }
  }

  // ARB4: No German transliterations in DE values
  for (const key of deKeys) {
    const value = deData[key];
    if (typeof value !== "string") continue;
    const translits = hasGermanTransliteration(value);
    for (const t of translits) {
      violations.push({ file: "app_de.arb", key, rule: "ARB4", message: `ASCII transliteration: ${t}` });
    }
  }

  return violations;
}

// ─── CLI Entry Point ────────────────────────────────────────────────────────

const isMain = process.argv[1] && (
  process.argv[1].endsWith("validate_i18n.ts") ||
  process.argv[1].endsWith("validate_i18n.js")
);

if (isMain) {
  const violations = validateArbFiles();

  // Write report
  const reportsDir = resolve(dirname(new URL(import.meta.url).pathname), "reports");
  if (!existsSync(reportsDir)) mkdirSync(reportsDir, { recursive: true });

  writeFileSync(
    resolve(reportsDir, "i18n_violations.json"),
    JSON.stringify(violations, null, 2),
  );

  // Console output
  console.log("\n📋 i18n Validation — ARB files\n");

  if (violations.length === 0) {
    console.log("✅ All checks passed.\n");
    process.exit(0);
  } else {
    console.log(`❌ ${violations.length} violation(s) found:\n`);
    const byRule = new Map<string, number>();
    for (const v of violations) {
      const count = byRule.get(v.rule) ?? 0;
      byRule.set(v.rule, count + 1);
      console.log(`  [${v.rule}] ${v.file} → ${v.key}: ${v.message}`);
    }
    console.log("\n── Summary by rule ──");
    for (const [rule, count] of [...byRule.entries()].sort()) {
      console.log(`  ${rule}: ${count}`);
    }
    console.log("");
    process.exit(1);
  }
}
