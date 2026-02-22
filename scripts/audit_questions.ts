#!/usr/bin/env npx tsx
/**
 * PHASE 1 — Comprehensive audit of questions.json
 *
 * Usage: npx tsx scripts/audit_questions.ts
 */

import * as fs from 'fs';
import * as path from 'path';

// ─── Load ───────────────────────────────────────────────
const QUESTIONS_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const raw = fs.readFileSync(QUESTIONS_PATH, 'utf-8');
const questions: any[] = JSON.parse(raw);

console.log('═══════════════════════════════════════════════');
console.log('  QUESTIONS AUDIT REPORT');
console.log('═══════════════════════════════════════════════\n');

// ─── 1. BASIC COUNTS ───────────────────────────────────
console.log(`Total questions: ${questions.length}\n`);

// ─── 2. INTENSITY DISTRIBUTION ─────────────────────────
const intensityCounts: Record<number, number> = {};
for (let i = 1; i <= 10; i++) intensityCounts[i] = 0;
for (const q of questions) {
  const v = q.intensity;
  intensityCounts[v] = (intensityCounts[v] || 0) + 1;
}
console.log('── Intensity Distribution ──');
for (const [k, v] of Object.entries(intensityCounts)) {
  const bar = '█'.repeat(Math.round((v as number) / 10));
  console.log(`  ${k.padStart(2)}: ${String(v).padStart(4)}  ${bar}`);
}
console.log();

// ─── 3. MISSING TRANSLATIONS ───────────────────────────
const missingEn = questions.filter(q => !q.text_en || q.text_en.trim() === '').length;
const missingDe = questions.filter(q => !q.text_de || q.text_de.trim() === '').length;
const missingEs = questions.filter(q => !q.text_es || q.text_es.trim() === '').length;
console.log('── Missing Translations ──');
console.log(`  text_en missing: ${missingEn}`);
console.log(`  text_de missing: ${missingDe}`);
console.log(`  text_es missing: ${missingEs}\n`);

// ─── 4. CATEGORY / SUBCATEGORY ─────────────────────────
const categoryCounts: Record<string, number> = {};
const subcategoryCounts: Record<string, number> = {};
const catSubCounts: Record<string, number> = {};
for (const q of questions) {
  categoryCounts[q.category] = (categoryCounts[q.category] || 0) + 1;
  subcategoryCounts[q.subcategory] = (subcategoryCounts[q.subcategory] || 0) + 1;
  const key = `${q.category}/${q.subcategory}`;
  catSubCounts[key] = (catSubCounts[key] || 0) + 1;
}

console.log('── Categories ──');
const sortedCats = Object.entries(categoryCounts).sort((a, b) => b[1] - a[1]);
for (const [k, v] of sortedCats) {
  console.log(`  ${k.padEnd(25)} ${String(v).padStart(4)}`);
}
console.log(`  TOTAL unique categories: ${sortedCats.length}\n`);

console.log('── Subcategories ──');
const sortedSubs = Object.entries(subcategoryCounts).sort((a, b) => b[1] - a[1]);
for (const [k, v] of sortedSubs) {
  console.log(`  ${k.padEnd(25)} ${String(v).padStart(4)}`);
}
console.log(`  TOTAL unique subcategories: ${sortedSubs.length}\n`);

// ─── 5. NSFW / PREMIUM / ENERGY ────────────────────────
const nsfwTrue = questions.filter(q => q.is_nsfw === true).length;
const nsfwFalse = questions.filter(q => q.is_nsfw === false).length;
const premTrue = questions.filter(q => q.is_premium === true).length;
const premFalse = questions.filter(q => q.is_premium === false).length;
const energyCounts: Record<string, number> = {};
for (const q of questions) {
  energyCounts[q.energy] = (energyCounts[q.energy] || 0) + 1;
}
console.log('── NSFW / Premium / Energy ──');
console.log(`  is_nsfw=true:  ${nsfwTrue}`);
console.log(`  is_nsfw=false: ${nsfwFalse}`);
console.log(`  is_premium=true:  ${premTrue}`);
console.log(`  is_premium=false: ${premFalse}`);
for (const [k, v] of Object.entries(energyCounts)) {
  console.log(`  energy="${k}": ${v}`);
}
console.log();

// ─── 6. DUPLICATES ─────────────────────────────────────
console.log('── Exact Duplicates ──');
function findExactDups(field: string): { text: string; ids: string[] }[] {
  const map = new Map<string, string[]>();
  for (const q of questions) {
    const t = (q[field] || '').trim().toLowerCase();
    if (!t) continue;
    if (!map.has(t)) map.set(t, []);
    map.get(t)!.push(q.id);
  }
  return [...map.entries()].filter(([_, ids]) => ids.length > 1).map(([t, ids]) => ({ text: t.slice(0, 80), ids }));
}

for (const lang of ['text_en', 'text_de', 'text_es']) {
  const dups = findExactDups(lang);
  console.log(`  ${lang}: ${dups.length} duplicate clusters`);
  for (const d of dups.slice(0, 5)) {
    console.log(`    [${d.ids.join(', ')}] "${d.text}…"`);
  }
}
console.log();

// ─── 7. NEAR-DUPLICATES (bigram Jaccard) ───────────────
console.log('── Near-Duplicates (EN, Jaccard > 0.7) ──');
function bigrams(s: string): Set<string> {
  const clean = s.toLowerCase().replace(/[^a-z0-9 ]/g, '');
  const words = clean.split(/\s+/).filter(Boolean);
  const set = new Set<string>();
  for (let i = 0; i < words.length - 1; i++) {
    set.add(words[i] + ' ' + words[i + 1]);
  }
  return set;
}

function jaccard(a: Set<string>, b: Set<string>): number {
  let inter = 0;
  for (const x of a) if (b.has(x)) inter++;
  const union = a.size + b.size - inter;
  return union === 0 ? 0 : inter / union;
}

// Sample near-dup detection (first 400 to stay fast)
const nearDups: { id1: string; id2: string; sim: number; t1: string; t2: string }[] = [];
const bgCache = questions.map(q => bigrams(q.text_en || ''));
const SAMPLE = Math.min(questions.length, 600);
for (let i = 0; i < SAMPLE; i++) {
  for (let j = i + 1; j < SAMPLE; j++) {
    const sim = jaccard(bgCache[i], bgCache[j]);
    if (sim > 0.7) {
      nearDups.push({
        id1: questions[i].id,
        id2: questions[j].id,
        sim: Math.round(sim * 100) / 100,
        t1: (questions[i].text_en || '').slice(0, 60),
        t2: (questions[j].text_en || '').slice(0, 60),
      });
    }
  }
}
console.log(`  Found ${nearDups.length} near-dup pairs (sampled first ${SAMPLE})`);
for (const d of nearDups.slice(0, 10)) {
  console.log(`    ${d.id1} ↔ ${d.id2} (${d.sim}) "${d.t1}…"`);
}
console.log();

// ─── 8. BROKEN / BAD ENTRIES ───────────────────────────
console.log('── Broken / Quality Issues ──');

interface Issue {
  id: string;
  flags: string[];
  text_en: string;
  text_de: string;
  text_es: string;
}

const issues: Issue[] = [];

// Heuristic markers for AI-generated bloat
const AI_MARKERS_EN = [
  'for the plot',
  'without a backup plan',
  'on a random tuesday',
  'when nobody expected it',
  'when everyone was',
  'to feel seen',
  'to seem chill',
  'to feel included',
  'with low battery',
  'in a clearly charged moment',
  'in weekend chaos',
  'on impulse',
  'to avoid conflict',
  'to avoid awkward',
  'in a socially questionable',
  'participated in',
  'engaged in',
  'in a weird moment',
  'for attention',
  'in a strange moment',
  'in a seltsamen moment',
  'after too much overthinking',
  'um mitzuh',
  'zu wir',
  'zu verm',
];

const AI_MARKERS_DE = [
  'um locker zu wir',
  'um mitzuh',
  'zu verm',
  'um Pein',
  'für die Story',
  'an einem zufälligen',
  'als alle laut waren',
  'als alle leise waren',
  'in einem seltsamen moment',
  'ohne plan b',
  'als es niemand erwartet hat',
  'für in einem',
];

for (const q of questions) {
  const flags: string[] = [];
  const en = (q.text_en || '').trim();
  const de = (q.text_de || '').trim();
  const es = (q.text_es || '').trim();

  // Too long (good NHIE questions are < 100 chars typically)
  if (en.length > 120) flags.push('EN too long (' + en.length + ' chars)');
  if (de.length > 130) flags.push('DE too long (' + de.length + ' chars)');
  if (es.length > 130) flags.push('ES too long (' + es.length + ' chars)');

  // AI bloat markers
  const enLow = en.toLowerCase();
  const deLow = de.toLowerCase();
  for (const m of AI_MARKERS_EN) {
    if (enLow.includes(m)) {
      flags.push(`EN AI-bloat: "${m}"`);
      break; // one flag per language is enough
    }
  }
  for (const m of AI_MARKERS_DE) {
    if (deLow.includes(m)) {
      flags.push(`DE AI-bloat/broken: "${m}"`);
      break;
    }
  }

  // Truncated German (words cut off mid-word)
  if (/\b\w{1,3}$/.test(de) && de.length > 30) {
    // check if last word is suspiciously short (truncated)
    const lastWord = de.split(/\s+/).pop() || '';
    if (lastWord.length <= 3 && !['ich', 'nie', 'ein', 'aus', 'mir', 'dir', 'hat', 'war', 'bin', 'mal', 'dem', 'den', 'des', 'als', 'für', 'vor', 'bei', 'zum', 'und', 'zur'].includes(lastWord.toLowerCase())) {
      flags.push(`DE truncated (ends with "${lastWord}")`);
    }
  }

  // Truncated Spanish
  if (/\b\w{1,3}$/.test(es) && es.length > 30) {
    const lastWord = es.split(/\s+/).pop() || '';
    if (lastWord.length <= 3 && !['un', 'en', 'de', 'el', 'la', 'los', 'las', 'por', 'con', 'sin', 'que', 'ser', 'una', 'del', 'mas', 'más', 'fue', 'eso', 'tal'].includes(lastWord.toLowerCase())) {
      flags.push(`ES truncated (ends with "${lastWord}")`);
    }
  }

  // Intensity mismatch: NSFW content at low intensity
  if (q.is_nsfw && q.intensity < 6) flags.push('NSFW at low intensity');
  if (!q.is_nsfw && q.intensity >= 9) {
    // High intensity but not NSFW — might be OK, flag for review
    flags.push('intensity≥9 but not NSFW (review)');
  }

  // Energy mismatch
  if (q.intensity <= 3 && q.energy === 'heavy') flags.push('energy=heavy at intensity≤3');
  if (q.intensity >= 8 && q.energy === 'light') flags.push('energy=light at intensity≥8');

  // Multiple run-on clauses (count common connectors — good NHIE has 1-2 clauses)
  const clauseCount = (enLow.match(/\b(to |when |while |because |after |before |during |without |on a |in a |for the |that |which |by |if )/g) || []).length;
  if (clauseCount >= 5) flags.push(`EN run-on (${clauseCount} clause markers)`);

  if (flags.length > 0) {
    issues.push({ id: q.id, flags, text_en: en.slice(0, 100), text_de: de.slice(0, 100), text_es: es.slice(0, 100) });
  }
}

console.log(`  Total questions with issues: ${issues.length} / ${questions.length} (${Math.round(issues.length / questions.length * 100)}%)`);

// Count by flag type
const flagCounts: Record<string, number> = {};
for (const i of issues) {
  for (const f of i.flags) {
    const key = f.replace(/\(.*\)/, '(…)').replace(/".*"/, '"…"');
    flagCounts[key] = (flagCounts[key] || 0) + 1;
  }
}
console.log('\n  Issue type breakdown:');
for (const [k, v] of Object.entries(flagCounts).sort((a, b) => b[1] - a[1])) {
  console.log(`    ${String(v).padStart(5)} × ${k}`);
}
console.log();

// ─── 9. TOP 50 WORST OFFENDERS ─────────────────────────
console.log('── TOP 50 WORST OFFENDERS ──\n');
const sorted = [...issues].sort((a, b) => b.flags.length - a.flags.length);
for (const item of sorted.slice(0, 50)) {
  console.log(`  ${item.id} (${item.flags.length} issues)`);
  console.log(`    EN: ${item.text_en}…`);
  console.log(`    DE: ${item.text_de}…`);
  console.log(`    ES: ${item.text_es}…`);
  console.log(`    FLAGS: ${item.flags.join(' | ')}`);
  console.log();
}

// ─── 10. SUMMARY VERDICT ───────────────────────────────
const pctBad = Math.round(issues.length / questions.length * 100);
console.log('═══════════════════════════════════════════════');
console.log('  AUDIT VERDICT');
console.log('═══════════════════════════════════════════════');
console.log(`  ${questions.length} questions total`);
console.log(`  ${issues.length} have quality issues (${pctBad}%)`);
console.log(`  ${nearDups.length} near-duplicate pairs found (sampled ${SAMPLE})`);
console.log(`  Conclusion: ${pctBad > 50 ? 'DATASET REQUIRES FULL REWRITE' : pctBad > 20 ? 'SIGNIFICANT CLEANUP NEEDED' : 'MINOR FIXES NEEDED'}`);
console.log('═══════════════════════════════════════════════');
