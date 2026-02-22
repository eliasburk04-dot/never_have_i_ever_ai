#!/usr/bin/env npx tsx
/**
 * BATCH 9 — FINAL 2 for intensity 9
 */
import * as fs from 'fs';
import * as path from 'path';

type Energy = 'light' | 'medium' | 'heavy';
interface QuestionDef { en: string; de: string; es: string; category: string; subcategory: string; intensity: number; is_nsfw: boolean; }

function computeMetadata(q: QuestionDef) {
  const i = q.intensity;
  let energy: Energy = i <= 3 ? 'light' : i <= 6 ? 'medium' : 'heavy';
  const base = (i - 1) / 9;
  const nB = q.is_nsfw ? 0.1 : 0;
  const sf = Math.round(Math.min(1, base + nB + (Math.random() * 0.08 - 0.04)) * 100) / 100;
  const vC = ['confessions', 'deep', 'relationships', 'moral_gray'].includes(q.category) ? 0.1 : 0;
  const vl = Math.round(Math.min(1, base * 0.9 + vC + (Math.random() * 0.06 - 0.03)) * 100) / 100;
  return { energy, shock_factor: sf, vulnerability_level: vl, is_premium: i >= 7 || q.is_nsfw };
}

const BATCH9: QuestionDef[] = [
{ en: "Never have I ever had a meal that was so awkward I can still feel the tension when I think about it", de: "Ich hatte noch nie ein Essen, das so unangenehm war, dass ich die Anspannung immer noch spüren kann, wenn ich daran denke", es: "Nunca he tenido una comida tan incómoda que todavía puedo sentir la tensión cuando lo pienso", category: "food", subcategory: "cooking", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had someone I trusted deeply reveal my most vulnerable moment to others", de: "Noch nie hat jemand, dem ich zutiefst vertraut hab, meinen verletzlichsten Moment an andere weitererzählt", es: "Nunca alguien en quien confié profundamente ha revelado mi momento más vulnerable a otros", category: "relationships", subcategory: "heartbreak", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been involved in a dare that resulted in someone being hospitalized", de: "Ich war noch nie an einer Mutprobe beteiligt, die dazu geführt hat, dass jemand ins Krankenhaus musste", es: "Nunca he estado involucrado en un reto que resultó en que alguien fue hospitalizado", category: "risk", subcategory: "bets", intensity: 9, is_nsfw: false },
];

const BASE_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const base: any[] = JSON.parse(fs.readFileSync(BASE_PATH, 'utf-8'));

const seenEN = new Set<string>();
const deduped: any[] = [];
for (const q of base) {
  const key = q.text_en.toLowerCase().trim();
  if (!seenEN.has(key)) { seenEN.add(key); deduped.push(q); }
}

let added = 0;
for (const q of BATCH9) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) { continue; }
  seenEN.add(key);
  const meta = computeMetadata(q);
  deduped.push({
    id: `placeholder`,
    text_en: q.en, text_de: q.de, text_es: q.es,
    category: q.category, subcategory: q.subcategory, intensity: q.intensity,
    is_nsfw: q.is_nsfw, is_premium: meta.is_premium,
    shock_factor: meta.shock_factor, vulnerability_level: meta.vulnerability_level, energy: meta.energy,
  });
  added++;
}

for (let i = 0; i < deduped.length; i++) {
  deduped[i].id = `q${String(i + 1).padStart(4, '0')}`;
}

console.log(`Base: ${base.length} | Added: ${added} | Total: ${deduped.length}`);

const byInt = new Map<number, number>();
for (const q of deduped) byInt.set(q.intensity, (byInt.get(q.intensity) || 0) + 1);
console.log('\nDistribution by intensity:');
let allGood = true;
for (let i = 1; i <= 10; i++) {
  const c = byInt.get(i) || 0;
  const ok = c >= 160;
  if (!ok) allGood = false;
  console.log(`  ${i}: ${c} ${ok ? '✅' : `(need ${160 - c})`}`);
}
console.log(allGood ? '\n🎉 ALL INTENSITIES ≥ 160!' : '');

const byCat = new Map<string, number>();
for (const q of deduped) byCat.set(q.category, (byCat.get(q.category) || 0) + 1);
console.log('\nBy category:');
for (const [c, n] of [...byCat.entries()].sort((a, b) => b[1] - a[1])) console.log(`  ${c}: ${n}`);

console.log(`\nTotal: ${deduped.length}`);
fs.writeFileSync(BASE_PATH, JSON.stringify(deduped, null, 2) + '\n', 'utf-8');
console.log(`✅ Wrote ${deduped.length} questions to ${BASE_PATH}`);
