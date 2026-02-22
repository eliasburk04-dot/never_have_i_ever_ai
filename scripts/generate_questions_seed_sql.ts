import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';

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
  energy: 'light' | 'medium' | 'heavy';
}

function sqlLiteral(value: string): string {
  return `'${value.replace(/'/g, "''")}'`;
}

function boolLiteral(value: boolean): string {
  return value ? 'TRUE' : 'FALSE';
}

function numLiteral(value: number): string {
  if (!Number.isFinite(value)) return '0';
  return `${value}`;
}

function main() {
  const root = resolve(dirname(new URL(import.meta.url).pathname), '..');
  const jsonPath = resolve(root, 'app/assets/questions.json');
  const sqlDir = resolve(root, 'backend/sql');
  const outPath = resolve(sqlDir, 'questions_seed.sql');

  const raw = readFileSync(jsonPath, 'utf-8');
  const questions: Question[] = JSON.parse(raw);

  if (!existsSync(sqlDir)) mkdirSync(sqlDir, { recursive: true });

  const header = `-- Auto-generated from app/assets/questions.json\n-- Run after schema migration\n\n`;
  const columns = [
    'id',
    'game_key',
    'text_en',
    'text_de',
    'text_es',
    'category',
    'subcategory',
    'intensity',
    'is_nsfw',
    'is_premium',
    'shock_factor',
    'vulnerability_level',
    'energy',
    'status',
  ];

  const rows = questions.map((q) => `(${[
    sqlLiteral(q.id),
    sqlLiteral('never_have_i_ever'),
    sqlLiteral(q.text_en),
    sqlLiteral(q.text_de),
    sqlLiteral(q.text_es),
    sqlLiteral(q.category),
    sqlLiteral(q.subcategory),
    numLiteral(q.intensity),
    boolLiteral(q.is_nsfw),
    boolLiteral(q.is_premium),
    numLiteral(q.shock_factor),
    numLiteral(q.vulnerability_level),
    sqlLiteral(q.energy),
    sqlLiteral('active'),
  ].join(', ')})`);

  const chunkSize = 200;
  const chunks: string[] = [];
  for (let i = 0; i < rows.length; i += chunkSize) {
    const chunk = rows.slice(i, i + chunkSize).join(',\n');
    chunks.push(`INSERT INTO questions (${columns.join(', ')})\nVALUES\n${chunk}\nON CONFLICT (id) DO UPDATE SET\n  text_en = EXCLUDED.text_en,\n  text_de = EXCLUDED.text_de,\n  text_es = EXCLUDED.text_es,\n  category = EXCLUDED.category,\n  subcategory = EXCLUDED.subcategory,\n  intensity = EXCLUDED.intensity,\n  is_nsfw = EXCLUDED.is_nsfw,\n  is_premium = EXCLUDED.is_premium,\n  shock_factor = EXCLUDED.shock_factor,\n  vulnerability_level = EXCLUDED.vulnerability_level,\n  energy = EXCLUDED.energy,\n  status = EXCLUDED.status,\n  updated_at = now();`);
  }

  writeFileSync(outPath, `${header}${chunks.join('\n\n')}\n`, 'utf-8');
  console.log(`Wrote ${questions.length} seeded questions to ${outPath}`);
}

const isMain = process.argv[1] && (
  process.argv[1].endsWith('generate_questions_seed_sql.ts') ||
  process.argv[1].endsWith('generate_questions_seed_sql.js')
);

if (isMain) main();
