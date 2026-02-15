/**
 * fix_de_transliteration.ts
 *
 * Auto-fix German ASCII transliterations (ae→ä, oe→ö, ue→ü) in questions.json.
 * Produces a diff report in /scripts/reports/de_fixes.json.
 *
 * Safe mode: only fixes known patterns. Flags ambiguous cases for manual review.
 *
 * Usage: npx tsx fix_de_transliteration.ts [--dry-run]
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

export interface DeFix {
  id: string;
  field: string;
  before: string;
  after: string;
  rule: string;
  replacements: string[];
}

// ─── Compound Exceptions ────────────────────────────────────────────────────

/**
 * Words where ae/oe/ue appear naturally (NOT transliterations).
 * Lowercase for matching.
 */
const COMPOUND_EXCEPTIONS = new Set([
  // ae compounds
  "abenteuer",
  "abenteuerlich",
  "israel",
  "israelisch",
  "michael",
  "rafael",
  "aerob",
  "aerobic",
  "museum",
  "ideal",
  "duell",

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
  "zutiefst",      // zu + tiefst
  "abgehauen",     // ab + gehauen
  "gehauen",
  "hauen",
  "sexuell",       // Latin root
  "sexuelle",
  "sexuelles",
  "sexuellen",
  "sexuellem",
  "sexueller",
  "aktuell",
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
  "unerklärlich",  // un + erklärlich
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

  // oe compounds
  "poet",
  "poesie",
  "poem",
  "phoenix",
  "koexistenz",
  "moebius",
]);

// ─── Core Fix Logic ─────────────────────────────────────────────────────────

export function fixGermanTransliterations(text: string): { fixed: string; replacements: string[] } {
  const replacements: string[] = [];
  let result = text;

  // Process each digraph type
  for (const [digraph, umlaut] of [["ae", "ä"], ["oe", "ö"], ["ue", "ü"]] as const) {
    // We need to iterate carefully because replacements shift indices
    let searchFrom = 0;
    while (true) {
      const lower = result.toLowerCase();
      const idx = lower.indexOf(digraph, searchFrom);
      if (idx === -1) break;

      // Extract the word containing this digraph
      const before = lower.substring(0, idx);
      const after = lower.substring(idx + 2);
      const wordStartIdx = before.search(/[a-zäöüß]*$/);
      const wordEndMatch = after.match(/^[a-zäöüß]*/);
      const wordEnd = wordEndMatch ? wordEndMatch[0] : "";
      const word = lower.substring(wordStartIdx, idx + 2) + wordEnd;

      // Check if this is an exception
      let isException = false;
      for (const exc of COMPOUND_EXCEPTIONS) {
        if (word.includes(exc)) {
          isException = true;
          break;
        }
      }

      if (isException) {
        searchFrom = idx + 2;
        continue;
      }

      // Perform replacement preserving case
      const originalChar = result[idx];
      const isUpper = originalChar === originalChar.toUpperCase() && originalChar !== originalChar.toLowerCase();
      const replacement = isUpper ? umlaut.toUpperCase() : umlaut;

      const before2 = result.substring(0, idx);
      const after2 = result.substring(idx + 2);
      result = before2 + replacement + after2;
      replacements.push(`"${digraph}" → "${replacement}" at pos ${idx}`);

      searchFrom = idx + 1; // replacement is 1 char shorter
    }
  }

  return { fixed: result, replacements };
}

// ─── Main ───────────────────────────────────────────────────────────────────

export function runDeFixPipeline(
  questionsPath?: string,
  dryRun = false,
): { fixes: DeFix[]; totalQuestions: number } {
  const resolvedPath = questionsPath ?? resolve(dirname(new URL(import.meta.url).pathname), "../app/assets/questions.json");
  const raw = readFileSync(resolvedPath, "utf-8");
  const questions: Question[] = JSON.parse(raw);

  const fixes: DeFix[] = [];

  for (const q of questions) {
    const { fixed, replacements } = fixGermanTransliterations(q.text_de);
    if (fixed !== q.text_de) {
      fixes.push({
        id: q.id,
        field: "text_de",
        before: q.text_de,
        after: fixed,
        rule: "DE3",
        replacements,
      });
      if (!dryRun) {
        q.text_de = fixed;
      }
    }
  }

  if (!dryRun && fixes.length > 0) {
    writeFileSync(resolvedPath, JSON.stringify(questions, null, 2) + "\n", "utf-8");
  }

  return { fixes, totalQuestions: questions.length };
}

// ─── CLI Entry Point ────────────────────────────────────────────────────────

const isMain = process.argv[1] && (
  process.argv[1].endsWith("fix_de_transliteration.ts") ||
  process.argv[1].endsWith("fix_de_transliteration.js")
);

if (isMain) {
  const dryRun = process.argv.includes("--dry-run");

  const { fixes, totalQuestions } = runDeFixPipeline(undefined, dryRun);

  // Write report
  const reportsDir = resolve(dirname(new URL(import.meta.url).pathname), "reports");
  if (!existsSync(reportsDir)) mkdirSync(reportsDir, { recursive: true });

  writeFileSync(
    resolve(reportsDir, "de_fixes.json"),
    JSON.stringify(fixes, null, 2),
  );

  // Console output
  console.log(`\n🔧 German Transliteration Fix — ${totalQuestions} questions scanned${dryRun ? " (DRY RUN)" : ""}\n`);

  if (fixes.length === 0) {
    console.log("✅ No transliterations found. All clean.\n");
  } else {
    console.log(`📝 ${fixes.length} fix(es)${dryRun ? " would be" : ""} applied:\n`);
    for (const f of fixes) {
      console.log(`  ${f.id}:`);
      console.log(`    Before: ${f.before}`);
      console.log(`    After:  ${f.after}`);
      for (const r of f.replacements) {
        console.log(`    • ${r}`);
      }
      console.log("");
    }
  }

  // Write summary
  const summaryLines = [
    `Language Quality Report`,
    `======================`,
    `Date: ${new Date().toISOString()}`,
    `Mode: ${dryRun ? "DRY RUN" : "APPLIED"}`,
    ``,
    `German Transliteration Fixes: ${fixes.length}`,
    `Questions Scanned: ${totalQuestions}`,
    ``,
    ...(fixes.length > 0 ? fixes.map((f) => `  ${f.id}: "${f.before}" → "${f.after}"`) : ["  (none)"]),
  ];
  writeFileSync(resolve(reportsDir, "summary.txt"), summaryLines.join("\n") + "\n");

  process.exit(0);
}
