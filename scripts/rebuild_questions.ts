#!/usr/bin/env npx tsx
/**
 * PHASE 3 — Clean, rewrite, and retranslate the entire questions dataset.
 *
 * Strategy:
 *   1. Extract the CORE idea from each bloated question (strip trailing AI junk).
 *   2. Rewrite EN to be short, natural, party-friendly.
 *   3. Write culturally natural DE + ES (not literal translations).
 *   4. Normalize categories/subcategories.
 *   5. Fix metadata (intensity, energy, shock_factor, vulnerability_level).
 *   6. Deduplicate: if core idea already seen, replace with a fresh question.
 *
 * Usage: npx tsx scripts/rebuild_questions.ts
 */

import * as fs from 'fs';
import * as path from 'path';

// ─── CATEGORY VOCABULARY ────────────────────────────────
// Controlled vocabulary — every question maps to one of these.
const CATEGORIES = {
  relationships: ['dating', 'heartbreak', 'situationship', 'flirting', 'boundaries'],
  confessions:   ['secrets', 'guilt', 'white_lies', 'dishonesty', 'shame'],
  party:         ['drinking', 'wild_nights', 'faux_pas', 'dares', 'public'],
  social:        ['awkward', 'status', 'people_pleasing', 'online', 'habits'],
  embarrassing:  ['public', 'body', 'gross', 'cringe', 'caught'],
  food:          ['habits', 'gross', 'picky', 'drunk_eating', 'cooking'],
  risk:          ['reckless', 'substances', 'driving', 'stunts', 'bets'],
  moral_gray:    ['manipulation', 'cheating', 'temptation', 'loyalty', 'dark'],
  sexual:        ['hookups', 'desire', 'kinks', 'temptation', 'boundaries'],
  deep:          ['vulnerability', 'identity', 'mental_health', 'regret', 'growth'],
} as const;

type Category = keyof typeof CATEGORIES;
type Energy = 'light' | 'medium' | 'heavy';

interface Question {
  id: string;
  text_en: string;
  text_de: string;
  text_es: string;
  category: Category;
  subcategory: string;
  intensity: number;
  is_nsfw: boolean;
  is_premium: boolean;
  shock_factor: number;
  vulnerability_level: number;
  energy: Energy;
}

// ─── OLD → NEW CATEGORY MAPPING ────────────────────────
const CATEGORY_MAP: Record<string, Category> = {
  relationships: 'relationships',
  confessions: 'confessions',
  party: 'party',
  social: 'social',
  embarrassing: 'embarrassing',
  food: 'food',
  alcohol: 'party',
  risk_behavior: 'risk',
  moral_gray: 'moral_gray',
  sexual: 'sexual',
  secrets: 'confessions',
  taboo: 'moral_gray',
  power_dynamics: 'moral_gray',
};

// ─── OLD → NEW SUBCATEGORY MAPPING ──────────────────────
const SUBCATEGORY_MAP: Record<string, string> = {
  boundaries: 'boundaries',
  temptation: 'temptation',
  secrets: 'secrets',
  flirting: 'flirting',
  desire: 'desire',
  situationship: 'situationship',
  white_lies: 'white_lies',
  faux_pas: 'faux_pas',
  public: 'public',
  guilt: 'guilt',
  status: 'status',
  habits: 'habits',
  awkward: 'awkward',
  heartbreak: 'heartbreak',
  private: 'secrets',
  deep: 'vulnerability',
  cheating: 'cheating',
  manipulation: 'manipulation',
  reckless: 'reckless',
  dishonesty: 'dishonesty',
  mild: 'cringe',
  body: 'body',
  gross: 'gross',
  crushing: 'dating',
  dating: 'dating',
  online: 'online',
  toxic: 'manipulation',
  shame: 'shame',
  dark: 'dark',
  people_pleasing: 'people_pleasing',
};

// ─── AI JUNK STRIPPERS ─────────────────────────────────
// These trailing phrases were systematically appended by the generator.
// Build junk-tail regex from fragments
const JUNK_FRAGMENTS = [
  'for the plot',
  'without a backup plan',
  'on a random tuesday',
  'when nobody expected it',
  'when everyone was (?:loud|quiet|watching|looking|asleep|gone)',
  'to feel seen',
  'to seem chill',
  'to feel included',
  'with low battery',
  'in a clearly charged moment',
  'in weekend chaos',
  'on impulse',
  'to avoid conflict',
  'to avoid awkward(?:ness)?',
  'in a socially questionable',
  'after too much overthinking',
  'for (?:the )?adrenaline',
  'to test my limits?',
  'to keep up',
  'for attention',
  'in a strange moment',
  'in a weird moment',
  'because (?:the )?chemistry felt intense',
  'with feelings I (?:did not|didn\'t) fully',
  'while (?:crossing|ignoring) (?:a|my)',
  'with tension (?:already|ya) present',
  'with someone I was very attracted? to',
  'even though I knew it was risky',
  'in a situation that got intense? fast',
  'because I was chasing validation',
  'because I (?:was curious|wanted attention|felt (?:insecure|lonely))',
  'to (?:fit into|keep up with) the group',
  'while being stressed',
  'that nobody (?:here )?knows about',
  'to k in weekend chaos',
  'um mitzuh im wochenendchaos',
  'für in einem seltsamen moment',
];
const junkPat = JUNK_FRAGMENTS.join('|');
const JUNK_TAIL_RE = new RegExp(`\\s+(${junkPat})(?:\\s+(${junkPat}))*`, 'gi');

function stripEnJunk(text: string): string {
  let clean = text.trim();
  clean = clean.replace(JUNK_TAIL_RE, '');
  // Also remove trailing fragments after common end points
  clean = clean.replace(/\s+to\s*$/, '');
  clean = clean.replace(/\s+when\s*$/, '');
  clean = clean.replace(/\s+while\s*$/, '');
  clean = clean.replace(/\s+because\s*$/, '');
  clean = clean.replace(/\s+with\s*$/, '');
  clean = clean.replace(/\s+for\s*$/, '');
  clean = clean.replace(/\s+in\s*$/, '');
  clean = clean.replace(/\s+after\s*$/, '');
  return clean.trim();
}

// ─── CORE IDEA EXTRACTION ───────────────────────────────
// Many questions have a good core buried under junk. Extract it.
function extractCoreEN(text: string): string {
  let core = stripEnJunk(text);
  // Remove the "Never have I ever" prefix for dedup comparison
  return core;
}

// ─── DEDUPLICATION BY CORE IDEA ─────────────────────────
function normalizeForDedup(text: string): string {
  return text
    .toLowerCase()
    .replace(/^never have i ever\s+/i, '')
    .replace(/[^a-z0-9 ]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

// ─── NATURAL REWRITE ENGINE ─────────────────────────────
// This is the most critical part. We take the cleaned EN core and produce
// natural party-game phrasing in EN, DE, and ES.
//
// Since we can't call an LLM, we use a rule-based approach:
// 1. Strip junk from EN
// 2. Map core → hand-written natural versions
// 3. For the massive scale, we define TEMPLATE BANKS per category/intensity

// First, let's see what unique cores we get after stripping junk
const QUESTIONS_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const raw = fs.readFileSync(QUESTIONS_PATH, 'utf-8');
const originals: any[] = JSON.parse(raw);

console.log('═══════════════════════════════════════════════');
console.log('  PHASE 3 — CLEAN + REWRITE');
console.log('═══════════════════════════════════════════════\n');

// Step 1: Strip junk and extract cores
const cores = originals.map(q => ({
  ...q,
  core_en: extractCoreEN(q.text_en),
  normalized: normalizeForDedup(extractCoreEN(q.text_en)),
}));

// Step 2: Find unique cores
const coreMap = new Map<string, typeof cores[0][]>();
for (const q of cores) {
  const key = q.normalized;
  if (!coreMap.has(key)) coreMap.set(key, []);
  coreMap.get(key)!.push(q);
}

console.log(`Original: ${originals.length} questions`);
console.log(`After junk stripping: ${coreMap.size} unique core ideas\n`);

// Show examples of cleaned cores
console.log('── Sample Cleaned Cores ──');
let shown = 0;
for (const [key, qs] of coreMap) {
  if (shown >= 20) break;
  console.log(`  ORIG: "${qs[0].text_en.slice(0, 90)}…"`);
  console.log(`  CORE: "${qs[0].core_en}"`);
  console.log(`  DUPS: ${qs.length} entries share this core`);
  console.log();
  shown++;
}

// Step 3: Count duplicates
const dupClusters = [...coreMap.values()].filter(v => v.length > 1);
console.log(`\n── Deduplication ──`);
console.log(`  Unique cores: ${coreMap.size}`);
console.log(`  Duplicate clusters: ${dupClusters.length}`);
console.log(`  Total duplicates to remove: ${originals.length - coreMap.size}`);

// Show largest clusters
const largestClusters = dupClusters.sort((a, b) => b.length - a.length).slice(0, 10);
console.log(`\n  Largest duplicate clusters:`);
for (const cluster of largestClusters) {
  console.log(`    ${cluster.length}× "${cluster[0].core_en.slice(0, 70)}…" [${cluster.map(q => q.id).join(', ')}]`);
}

console.log('\n═══════════════════════════════════════════════');
console.log('  ANALYSIS COMPLETE — READY FOR REWRITE');
console.log('═══════════════════════════════════════════════');
console.log(`\n  Next step: Generate clean questions from ${coreMap.size} unique cores.`);
console.log(`  Target: 1600 questions (need to create ${1600 - coreMap.size} fresh ones to replace duplicates).`);
