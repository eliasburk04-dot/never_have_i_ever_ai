import { describe, it, expect, afterEach } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

import { validateQuestionPool } from '../validate_question_pool';

const __filename = fileURLToPath(import.meta.url);
const __dirname2 = dirname(__filename);
const TMP_DIR = resolve(__dirname2, '__tmp_question_pool__');
const TMP_FILE = resolve(TMP_DIR, 'questions.json');

function makeQuestion(i: number, intensity: number, nsfw: boolean) {
  const id = `q${String(i + 1).padStart(4, '0')}`;
  const category = nsfw ? 'sexual' : 'social';
  const subcategory = nsfw ? 'desire' : 'habits';
  const energy = intensity >= 8 ? 'heavy' : intensity >= 4 ? 'medium' : 'light';
  return {
    id,
    text_en: `Never have I ever done unique thing ${i}`,
    text_de: `Ich hab noch nie einzigartige Sache ${i} gemacht`,
    text_es: `Nunca he hecho cosa única ${i}`,
    category,
    subcategory,
    intensity,
    is_nsfw: nsfw,
    is_premium: nsfw,
    shock_factor: Math.min(1, 0.1 + intensity * 0.08),
    vulnerability_level: Math.min(1, 0.1 + intensity * 0.07),
    energy,
  };
}

function writeQuestions(data: any[]) {
  mkdirSync(TMP_DIR, { recursive: true });
  writeFileSync(TMP_FILE, `${JSON.stringify(data, null, 2)}\n`, 'utf-8');
}

afterEach(() => {
  rmSync(TMP_DIR, { recursive: true, force: true });
});

describe('validate_question_pool — unit tests', () => {
  it('passes required thresholds with balanced large dataset', () => {
    const questions: any[] = [];
    for (let i = 0; i < 1500; i++) {
      const intensity = (i % 10) + 1;
      const nsfw = i < 120;
      questions.push(makeQuestion(i, intensity, nsfw));
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.errors).toEqual([]);
    expect(report.total).toBe(1500);
    expect(report.nsfwCount).toBeGreaterThanOrEqual(100);
    expect(report.countsByIntensity['1']).toBeGreaterThanOrEqual(120);
    expect(report.countsByIntensity['10']).toBeGreaterThanOrEqual(120);
  });

  it('errors when total < 1500', () => {
    const questions: any[] = [];
    for (let i = 0; i < 500; i++) {
      questions.push(makeQuestion(i, (i % 10) + 1, false));
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.errors.some((e) => e.includes('Total questions'))).toBe(true);
  });

  it('errors when NSFW < 100', () => {
    const questions: any[] = [];
    for (let i = 0; i < 1500; i++) {
      questions.push(makeQuestion(i, (i % 10) + 1, false));
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.errors.some((e) => e.includes('NSFW'))).toBe(true);
  });

  it('errors when an intensity bucket is under 120', () => {
    const questions: any[] = [];
    for (let i = 0; i < 1500; i++) {
      const nsfw = i < 120;
      questions.push(makeQuestion(i, 1, nsfw)); // all intensity 1
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.errors.some((e) => e.includes('Intensity'))).toBe(true);
  });

  it('detects duplicates and missing translations', () => {
    const questions = [
      makeQuestion(0, 1, false),
      {
        ...makeQuestion(1, 1, false),
        text_en: 'Never have I ever done unique thing 0',
        text_de: '',
      },
    ];
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.duplicateTexts.length).toBeGreaterThan(0);
    expect(report.missingTranslations.length).toBe(1);
  });

  it('counts categories and subcategories', () => {
    const categories = ['food', 'social', 'party', 'deep', 'risk'];
    const questions: any[] = [];
    for (let i = 0; i < 1500; i++) {
      const q = makeQuestion(i, (i % 10) + 1, i < 120);
      q.category = categories[i % categories.length];
      questions.push(q);
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(Object.keys(report.countsByCategory).length).toBe(5);
  });

  it('counts energy distribution', () => {
    const questions: any[] = [];
    for (let i = 0; i < 1500; i++) {
      questions.push(makeQuestion(i, (i % 10) + 1, i < 120));
    }
    writeQuestions(questions);

    const report = validateQuestionPool(TMP_FILE);
    expect(report.countsByEnergy['light']).toBeGreaterThan(0);
    expect(report.countsByEnergy['medium']).toBeGreaterThan(0);
    expect(report.countsByEnergy['heavy']).toBeGreaterThan(0);
  });
});

// ─── Integration: Real Dataset ──────────────────────────────────────────────

describe('Integration: real questions.json pool validation', () => {
  it('passes all required checks with 0 errors', () => {
    const report = validateQuestionPool(); // uses default path
    expect(report.total).toBeGreaterThanOrEqual(1500);
    expect(report.errors).toEqual([]);
    expect(report.missingTranslations).toEqual([]);
    expect(report.duplicateTexts).toEqual([]);
  });

  it('has at least 100 NSFW questions', () => {
    const report = validateQuestionPool();
    expect(report.nsfwCount).toBeGreaterThanOrEqual(100);
  });

  it('has at least 120 questions per intensity level', () => {
    const report = validateQuestionPool();
    for (let i = 1; i <= 10; i++) {
      expect(report.countsByIntensity[String(i)]).toBeGreaterThanOrEqual(120);
    }
  });

  it('has 10 categories', () => {
    const report = validateQuestionPool();
    expect(Object.keys(report.countsByCategory).length).toBe(10);
  });

  it('has 3 energy levels all populated', () => {
    const report = validateQuestionPool();
    expect(Object.keys(report.countsByEnergy).length).toBe(3);
    expect(report.countsByEnergy['light']).toBeGreaterThan(0);
    expect(report.countsByEnergy['medium']).toBeGreaterThan(0);
    expect(report.countsByEnergy['heavy']).toBeGreaterThan(0);
  });

  it('has no exact duplicate texts in any language', () => {
    const report = validateQuestionPool();
    expect(report.duplicateTexts).toEqual([]);
  });
});
