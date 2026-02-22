import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';

type Energy = 'light' | 'medium' | 'heavy';

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
  energy: Energy;
}

interface ValidationSummary {
  total: number;
  nsfwCount: number;
  countsByIntensity: Record<string, number>;
  countsByCategory: Record<string, number>;
  countsBySubcategory: Record<string, number>;
  countsByEnergy: Record<string, number>;
  countsByNsfw: Record<string, number>;
  missingTranslations: string[];
  duplicateTexts: Array<{ lang: 'en' | 'de' | 'es'; text: string; ids: string[] }>;
  crossLanguageDuplicates: Array<{ id: string; langs: string[]; text: string }>;
  nearDuplicates: Array<{ lang: 'en' | 'de' | 'es'; a: string; b: string; score: number }>;
  warnings: string[];
  errors: string[];
}

const MIN_TOTAL = 1500;
const MIN_PER_INTENSITY = 120;
const MIN_NSFW = 100;

function inc(map: Record<string, number>, key: string): void {
  map[key] = (map[key] ?? 0) + 1;
}

function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .replace(/^never have i ever\s+/i, '')
    .replace(/^ich hab noch nie\s+/i, '')
    .replace(/^yo nunca nunca\s+/i, '')
    .replace(/[^\p{L}\p{N}\s]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function tokenSet(text: string): Set<string> {
  const tokens = normalizeText(text)
    .split(' ')
    .map((t) => t.trim())
    .filter((t) => t.length >= 3);
  return new Set(tokens);
}

function jaccard(a: Set<string>, b: Set<string>): number {
  if (a.size === 0 && b.size === 0) return 1;
  let inter = 0;
  for (const t of a) {
    if (b.has(t)) inter++;
  }
  const union = a.size + b.size - inter;
  return union === 0 ? 0 : inter / union;
}

function findDuplicatesByLanguage(
  questions: Question[],
  lang: 'en' | 'de' | 'es',
): Array<{ lang: 'en' | 'de' | 'es'; text: string; ids: string[] }> {
  const map = new Map<string, string[]>();
  for (const q of questions) {
    const text = lang === 'en' ? q.text_en : lang === 'de' ? q.text_de : q.text_es;
    const key = normalizeText(text);
    const ids = map.get(key) ?? [];
    ids.push(q.id);
    map.set(key, ids);
  }

  const out: Array<{ lang: 'en' | 'de' | 'es'; text: string; ids: string[] }> = [];
  for (const [text, ids] of map.entries()) {
    if (ids.length > 1) out.push({ lang, text, ids });
  }
  return out;
}

function findNearDuplicates(
  questions: Question[],
  lang: 'en' | 'de' | 'es',
  threshold = 0.88,
): Array<{ lang: 'en' | 'de' | 'es'; a: string; b: string; score: number }> {
  const seen = new Set<string>();
  const out: Array<{ lang: 'en' | 'de' | 'es'; a: string; b: string; score: number }> = [];
  const maxPairs = 250;

  const entries = questions.map((q) => {
    const text = lang === 'en' ? q.text_en : lang === 'de' ? q.text_de : q.text_es;
    return { id: q.id, text, tokens: tokenSet(text), intensity: q.intensity, category: q.category };
  });

  const buckets = new Map<string, typeof entries>();
  for (const e of entries) {
    const first = [...e.tokens][0] ?? '_';
    const key = `${e.intensity}:${e.category}:${first}`;
    buckets.set(key, [...(buckets.get(key) ?? []), e]);
  }

  for (const bucket of buckets.values()) {
    for (let i = 0; i < bucket.length; i++) {
      for (let j = i + 1; j < bucket.length; j++) {
        const a = bucket[i];
        const b = bucket[j];
        const sig = `${a.id}:${b.id}`;
        if (seen.has(sig)) continue;
        seen.add(sig);

        const score = jaccard(a.tokens, b.tokens);
        if (score >= threshold) {
          out.push({ lang, a: a.id, b: b.id, score: Math.round(score * 100) / 100 });
          if (out.length >= maxPairs) return out;
        }
      }
    }
  }

  return out;
}

function toSortedRecord(map: Record<string, number>): Record<string, number> {
  return Object.fromEntries(Object.entries(map).sort(([a], [b]) => a.localeCompare(b)));
}

export function validateQuestionPool(questionsPath?: string): ValidationSummary {
  const resolvedPath =
    questionsPath ?? resolve(dirname(new URL(import.meta.url).pathname), '../app/assets/questions.json');
  const raw = readFileSync(resolvedPath, 'utf-8');
  const questions: Question[] = JSON.parse(raw);

  const countsByIntensity: Record<string, number> = {};
  const countsByCategory: Record<string, number> = {};
  const countsBySubcategory: Record<string, number> = {};
  const countsByEnergy: Record<string, number> = {};
  const countsByNsfw: Record<string, number> = { true: 0, false: 0 };

  const missingTranslations: string[] = [];
  const crossLanguageDuplicates: Array<{ id: string; langs: string[]; text: string }> = [];
  const errors: string[] = [];
  const warnings: string[] = [];

  for (const q of questions) {
    inc(countsByIntensity, String(q.intensity));
    inc(countsByCategory, q.category || '(empty)');
    inc(countsBySubcategory, q.subcategory || '(empty)');
    inc(countsByEnergy, q.energy || '(empty)');
    inc(countsByNsfw, String(q.is_nsfw));

    if (!q.text_en?.trim() || !q.text_de?.trim() || !q.text_es?.trim()) {
      missingTranslations.push(q.id);
    }

    const pairs: Array<[string, string]> = [
      ['en', q.text_en],
      ['de', q.text_de],
      ['es', q.text_es],
    ];
    const byText = new Map<string, string[]>();
    for (const [lang, text] of pairs) {
      const key = normalizeText(text);
      byText.set(key, [...(byText.get(key) ?? []), lang]);
    }
    for (const [text, langs] of byText.entries()) {
      if (langs.length > 1) {
        crossLanguageDuplicates.push({ id: q.id, langs, text });
      }
    }
  }

  const duplicateTexts = [
    ...findDuplicatesByLanguage(questions, 'en'),
    ...findDuplicatesByLanguage(questions, 'de'),
    ...findDuplicatesByLanguage(questions, 'es'),
  ];

  const nearDuplicates = [
    ...findNearDuplicates(questions, 'en'),
    ...findNearDuplicates(questions, 'de'),
    ...findNearDuplicates(questions, 'es'),
  ];

  if (questions.length < MIN_TOTAL) {
    errors.push(`Total questions ${questions.length} < ${MIN_TOTAL}`);
  }

  const nsfwCount = countsByNsfw['true'] ?? 0;
  if (nsfwCount < MIN_NSFW) {
    errors.push(`NSFW questions ${nsfwCount} < ${MIN_NSFW}`);
  }

  for (let i = 1; i <= 10; i++) {
    const c = countsByIntensity[String(i)] ?? 0;
    if (c < MIN_PER_INTENSITY) {
      errors.push(`Intensity ${i} has ${c} questions < ${MIN_PER_INTENSITY}`);
    }
  }

  if (missingTranslations.length > 0) {
    errors.push(`Missing translations in ${missingTranslations.length} question(s)`);
  }

  if (duplicateTexts.length > 0) {
    errors.push(`Duplicate texts detected: ${duplicateTexts.length}`);
  }

  const intensityValues = Array.from({ length: 10 }, (_, idx) => countsByIntensity[String(idx + 1)] ?? 0);
  const minIntensity = Math.min(...intensityValues);
  const maxIntensity = Math.max(...intensityValues);
  const meanIntensity = intensityValues.reduce((a, b) => a + b, 0) / intensityValues.length;
  const spreadRatio = meanIntensity === 0 ? 0 : (maxIntensity - minIntensity) / meanIntensity;
  if (spreadRatio > 0.25) {
    warnings.push(`Intensity distribution spread is high (${spreadRatio.toFixed(2)} > 0.25)`);
  }

  if (crossLanguageDuplicates.length > 0) {
    warnings.push(`Cross-language identical texts found in ${crossLanguageDuplicates.length} question(s)`);
  }

  if (nearDuplicates.length > 0) {
    warnings.push(`Near-duplicate candidates found: ${nearDuplicates.length}`);
  }

  return {
    total: questions.length,
    nsfwCount,
    countsByIntensity: toSortedRecord(countsByIntensity),
    countsByCategory: toSortedRecord(countsByCategory),
    countsBySubcategory: toSortedRecord(countsBySubcategory),
    countsByEnergy: toSortedRecord(countsByEnergy),
    countsByNsfw: toSortedRecord(countsByNsfw),
    missingTranslations,
    duplicateTexts,
    crossLanguageDuplicates,
    nearDuplicates,
    warnings,
    errors,
  };
}

const isMain =
  process.argv[1] &&
  (process.argv[1].endsWith('validate_question_pool.ts') ||
    process.argv[1].endsWith('validate_question_pool.js'));

if (isMain) {
  const report = validateQuestionPool();
  const reportsDir = resolve(dirname(new URL(import.meta.url).pathname), 'reports');
  if (!existsSync(reportsDir)) mkdirSync(reportsDir, { recursive: true });

  writeFileSync(resolve(reportsDir, 'question_pool_report.json'), `${JSON.stringify(report, null, 2)}\n`, 'utf-8');

  console.log('\nQuestion Pool Validation\n');
  console.log(`Total: ${report.total}`);
  console.log(`NSFW: ${report.nsfwCount}`);
  console.log('Intensity counts:');
  for (let i = 1; i <= 10; i++) {
    console.log(`  ${i}: ${report.countsByIntensity[String(i)] ?? 0}`);
  }
  console.log(`Categories: ${Object.keys(report.countsByCategory).length}`);
  console.log(`Subcategories: ${Object.keys(report.countsBySubcategory).length}`);

  if (report.warnings.length > 0) {
    console.log('\nWarnings:');
    for (const warning of report.warnings) {
      console.log(`  - ${warning}`);
    }
  }

  if (report.errors.length > 0) {
    console.log('\nErrors:');
    for (const error of report.errors) {
      console.log(`  - ${error}`);
    }
    process.exit(1);
  }

  console.log('\nAll required checks passed.\n');
}
