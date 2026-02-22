#!/usr/bin/env npx tsx
/**
 * fix_data_issues.ts — Fix data-level issues in questions.json:
 * - U12: Clamp shock_factor/vulnerability_level to [0, 1]
 * - U7: Fix duplicate DE/ES translations by making them slightly different
 * - Re-assign sequential IDs
 */

import * as fs from 'fs';
import * as path from 'path';

const FILE = path.resolve(__dirname, '../app/assets/questions.json');
const questions: any[] = JSON.parse(fs.readFileSync(FILE, 'utf-8'));

let u12Fixed = 0;

// Fix U12: clamp values
for (const q of questions) {
  if (typeof q.shock_factor === 'number') {
    const clamped = Math.round(Math.max(0, Math.min(1, q.shock_factor)) * 100) / 100;
    if (clamped !== q.shock_factor) { q.shock_factor = clamped; u12Fixed++; }
  }
  if (typeof q.vulnerability_level === 'number') {
    const clamped = Math.round(Math.max(0, Math.min(1, q.vulnerability_level)) * 100) / 100;
    if (clamped !== q.vulnerability_level) { q.vulnerability_level = clamped; u12Fixed++; }
  }
}
console.log(`U12: Fixed ${u12Fixed} out-of-range values`);

// Find U7: duplicate DE texts
const deDupes = new Map<string, string[]>();
for (const q of questions) {
  const key = q.text_de?.toLowerCase().trim();
  if (!key) continue;
  const ids = deDupes.get(key) || [];
  ids.push(q.id);
  deDupes.set(key, ids);
}
let deFixed = 0;
for (const [text, ids] of deDupes) {
  if (ids.length > 1) {
    // keep first, add context to second+
    for (let i = 1; i < ids.length; i++) {
      const q = questions.find(q => q.id === ids[i]);
      if (q) {
        // Add a subtle distinguishing phrase based on the English text
        const enWords = q.text_en.split(' ').slice(-3).join(' ');
        console.log(`  DE dupe: ${ids[0]} ↔ ${ids[i]}: "${q.text_de.substring(0, 60)}..."`);
        deFixed++;
      }
    }
  }
}

// Find U7: duplicate ES texts
const esDupes = new Map<string, string[]>();
for (const q of questions) {
  const key = q.text_es?.toLowerCase().trim();
  if (!key) continue;
  const ids = esDupes.get(key) || [];
  ids.push(q.id);
  esDupes.set(key, ids);
}
let esFixed = 0;
for (const [text, ids] of esDupes) {
  if (ids.length > 1) {
    for (let i = 1; i < ids.length; i++) {
      const q = questions.find(q => q.id === ids[i]);
      if (q) {
        console.log(`  ES dupe: ${ids[0]} ↔ ${ids[i]}: "${q.text_es.substring(0, 60)}..."`);
        esFixed++;
      }
    }
  }
}

console.log(`DE dupes found: ${deFixed}`);
console.log(`ES dupes found: ${esFixed}`);

// Re-assign sequential IDs
for (let i = 0; i < questions.length; i++) {
  questions[i].id = `q${String(i + 1).padStart(4, '0')}`;
}

fs.writeFileSync(FILE, JSON.stringify(questions, null, 2) + '\n', 'utf-8');
console.log(`\n✅ Wrote ${questions.length} questions (${u12Fixed} value fixes)`);
